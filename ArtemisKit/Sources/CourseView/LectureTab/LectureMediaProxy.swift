import Foundation
import Network

/// AVFoundation supplements its own cookie store even when supplied an empty cookie
/// list. Keep every media fetch in our isolated URLSession instead. Only opaque,
/// per-playback resource routes are exposed on the device's loopback interface.
final class LectureMediaProxy {
    private let policy: LectureMediaRequestPolicy
    private let isCurrent: () -> Bool
    private let nonce = UUID().uuidString
    private var listener: NWListener?
    private var port: UInt16?
    private let registry = LectureMediaResourceRegistry()
    private var leases: [UUID: String] = [:]
    private var connections: [UUID: NWConnection] = [:]
    private var fetches: [UUID: Fetch] = [:]

    init(policy: LectureMediaRequestPolicy, isCurrent: @escaping () -> Bool) {
        self.policy = policy
        self.isCurrent = isCurrent
    }

    @MainActor
    func start(source: URL) async throws -> URL {
        guard LectureMediaSource.classify(source) == .video, isCurrent() else { throw LectureMediaError.invalidURL }
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
        let listener = try NWListener(using: parameters)
        self.listener = listener
        listener.newConnectionHandler = { [weak self] in self?.accept($0) }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let startup = Startup(continuation)
            listener.stateUpdateHandler = { [weak self, weak listener] state in
                switch state {
                case .ready:
                    self?.port = listener?.port?.rawValue
                    startup.finish(.success(()))
                case .failed(let error): startup.finish(.failure(error))
                case .cancelled: startup.finish(.failure(CancellationError()))
                default: break
                }
            }
            listener.start(queue: .main)
        }
        guard isCurrent() else { stop(); throw LectureMediaError.sessionChanged }
        return try localURL(registry.addRoot(source, role: .source(source)))
    }

    deinit {
        listener?.cancel()
        fetches.values.forEach { $0.cancel() }
        connections.values.forEach { $0.cancel() }
    }

    private final class Startup: @unchecked Sendable {
        private let lock = NSLock()
        private var continuation: CheckedContinuation<Void, Error>?
        init(_ continuation: CheckedContinuation<Void, Error>) { self.continuation = continuation }
        func finish(_ result: Result<Void, Error>) {
            let pending = lock.withLock { let value = continuation; continuation = nil; return value }
            pending?.resume(with: result)
        }
    }

    @MainActor
    func stop() {
        listener?.cancel()
        listener = nil
        for fetch in fetches.values { fetch.cancel() }
        fetches.removeAll()
        for connection in connections.values { connection.cancel() }
        connections.removeAll()
        leases.removeAll()
        registry.reset()
        port = nil
    }

    private func localURL(_ identifier: String) throws -> URL {
        guard let port, let url = URL(string: "http://127.0.0.1:\(port)/\(nonce)/\(identifier)") else { throw LectureMediaError.invalidURL }
        return url
    }

    private func accept(_ connection: NWConnection) {
        guard connections.count < 12, isCurrent() else { connection.cancel(); return }
        let id = UUID()
        connections[id] = connection
        connection.stateUpdateHandler = { [weak self] state in
            if case .failed = state { self?.finish(id) }
            if case .cancelled = state { self?.finish(id) }
        }
        connection.start(queue: .main)
        receiveHeaders(connection, id: id, accumulated: Data())
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self, weak connection] in
            if self?.fetches[id] == nil { connection?.cancel() }
        }
    }

    private func receiveHeaders(_ connection: NWConnection, id: UUID, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] data, _, done, error in
            guard let self, self.isCurrent(), error == nil else { self?.finish(id); return }
            var buffer = accumulated
            if let data { buffer.append(data) }
            guard buffer.count <= 16384 else { self.reject(connection, id: id, status: 431); return }
            if let boundary = buffer.range(of: Data("\r\n\r\n".utf8)) {
                guard let headers = String(data: buffer[..<boundary.lowerBound], encoding: .utf8) else { self.reject(connection, id: id); return }
                self.request(headers, connection: connection, id: id)
            } else if done { self.finish(id) }
            else { self.receiveHeaders(connection, id: id, accumulated: buffer) }
        }
    }

    private func request(_ raw: String, connection: NWConnection, id: UUID) {
        let lines = raw.components(separatedBy: "\r\n")
        let request = lines.first?.split(separator: " ") ?? []
        guard request.count == 3, ["GET", "HEAD"].contains(String(request[0])), request[2].hasPrefix("HTTP/1."),
              request[1].hasPrefix("/\(nonce)/"), !request[1].contains("?"),
              let resource = registry.resource(String(request[1].dropFirst(nonce.count + 2))), isCurrent() else {
            reject(connection, id: id, status: 404); return
        }
        var range: String?
        for line in lines.dropFirst() {
            if line.lowercased().hasPrefix("range:") {
                guard range == nil else { reject(connection, id: id); return }
                range = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                guard let range, LectureMediaProxyRequest.validRange(range) else { reject(connection, id: id); return }
            }
        }
        let identifier = String(request[1].dropFirst(nonce.count + 2))
        guard registry.acquire(identifier) != nil else { reject(connection, id: id, status: 404); return }
        leases[id] = identifier
        let fetch = Fetch(source: resource.url, role: resource.role, method: String(request[0]), range: range, policy: policy,
                          connection: connection, isCurrent: isCurrent, rewrite: { [weak self] value, base in
            guard let self else { throw CancellationError() }
            return try self.registry.rewrite(value, relativeTo: base, owner: identifier, localURL: self.localURL)
        }, finish: { [weak self] in self?.finish(id) })
        fetches[id] = fetch
        fetch.start()
        // Detect AVPlayer closing/cancelling a pending segment or range request.
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1) { [weak self] _, _, done, error in
            if done || error != nil { self?.finish(id) }
        }
    }

    private func reject(_ connection: NWConnection, id: UUID, status: Int = 400) {
        connection.send(content: Data("HTTP/1.1 \(status) Error\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".utf8),
                        completion: .contentProcessed { [weak self] _ in self?.finish(id) })
    }

    private func finish(_ id: UUID) {
        fetches.removeValue(forKey: id)?.cancel()
        if let resource = leases.removeValue(forKey: id) { registry.release(resource) }
        connections.removeValue(forKey: id)?.cancel()
    }
}

private extension LectureMediaProxy {
    final class Fetch: NSObject, URLSessionDataDelegate, @unchecked Sendable {
        let source: URL
        let role: LectureMediaResourceRole
        let method: String
        let range: String?
        let policy: LectureMediaRequestPolicy
        let connection: NWConnection
        let isCurrent: () -> Bool
        let rewrite: (String, URL) throws -> String
        let finish: () -> Void
        private var session: URLSession?
        private var task: URLSessionDataTask?
        private var response: HTTPURLResponse?
        private var playlist = false
        private var sniffedMedia = false
        private var buffer = Data()
        private var closed = false
        private var headersSent = false

        init(source: URL, role: LectureMediaResourceRole, method: String, range: String?, policy: LectureMediaRequestPolicy, connection: NWConnection,
             isCurrent: @escaping () -> Bool, rewrite: @escaping (String, URL) throws -> String, finish: @escaping () -> Void) {
            self.source = source; self.role = role; self.method = method; self.range = range; self.policy = policy
            self.connection = connection; self.isCurrent = isCurrent; self.rewrite = rewrite; self.finish = finish
        }

        func start() {
            var request = policy.request(for: source)
            request.httpMethod = role == .playlist ? "GET" : method
            request.setValue(role == .playlist ? nil : range, forHTTPHeaderField: "Range")
            request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
            let session = URLSession(configuration: LectureMediaDownloader.configuration(), delegate: self, delegateQueue: .main)
            self.session = session
            task = session.dataTask(with: request)
            task?.resume()
        }

        func cancel() {
            closed = true
            task?.cancel()
            session?.invalidateAndCancel()
            session = nil
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            guard isCurrent(), let destination = request.url, let from = response.url,
                  var redirect = policy.redirect(from: from, to: destination) else { completionHandler(nil); return }
            redirect.httpMethod = role == .playlist ? "GET" : method
            redirect.setValue(role == .playlist ? nil : range, forHTTPHeaderField: "Range")
            redirect.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
            completionHandler(redirect)
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            guard !closed, isCurrent(), let response = response as? HTTPURLResponse,
                  [200, 206, 416].contains(response.statusCode) else {
                completionHandler(.cancel); fail(); return
            }
            self.response = response
            if let encoding = response.value(forHTTPHeaderField: "Content-Encoding"), encoding.lowercased() != "identity" {
                completionHandler(.cancel); fail(); return
            }
            let mime = response.mimeType?.lowercased() ?? ""
            playlist = role == .playlist
            if !playlist && (mime.contains("mpegurl") || response.url.map({ LectureMediaResourceRole.source($0) == .playlist }) == true) {
                completionHandler(.cancel); fail(); return
            }
            // A server may ignore AVFoundation’s sniff range and return a complete playlist.
            // Only complete playlists can be rewritten; partial upstream responses fail closed.
            if playlist && response.statusCode != 200 { completionHandler(.cancel); fail(); return }
            if !playlist && method == "HEAD" { sendHeaders(response) }
            completionHandler(.allow)
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            guard !closed, isCurrent() else { cancel(); finish(); return }
            if playlist {
                guard buffer.count + data.count <= 2 * 1024 * 1024 else { fail(); return }
                buffer.append(data)
            } else {
                if !sniffedMedia {
                    buffer.append(data)
                    switch LectureMediaPrefix.classify(buffer) {
                    case .reject: fail(); return
                    case .waiting: return
                    case .media: break
                    }
                    sniffedMedia = true
                    guard let response else { fail(); return }
                    sendHeaders(response)
                    let pending = buffer
                    buffer.removeAll(keepingCapacity: false)
                    send(pending, task: dataTask)
                } else { send(data, task: dataTask) }
            }
        }

        private func send(_ data: Data, task: URLSessionDataTask) {
            task.suspend()
            connection.send(content: data, completion: .contentProcessed { [weak self, weak task] error in
                if error != nil { self?.cancel(); self?.finish() }
                else { task?.resume() }
            })
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            guard !closed else { return }
            guard error == nil, isCurrent(), let response else { fail(); return }
            if playlist {
                do {
                    guard let value = String(data: buffer, encoding: .utf8) else { throw LectureMediaError.unavailable }
                    let rewritten = try rewrite(value, response.url ?? source)
                    let data = Data(rewritten.utf8)
                    let header = "HTTP/1.1 200 OK\r\nContent-Type: application/vnd.apple.mpegurl\r\nContent-Length: \(data.count)\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"
                    connection.send(content: Data(header.utf8) + (method == "HEAD" ? Data() : data), completion: .contentProcessed { [weak self] _ in self?.finish() })
                } catch { fail() }
            } else {
                if !buffer.isEmpty {
                    // A truncated possible playlist prefix is not safe to expose.
                    fail(); return
                }
                if !headersSent { sendHeaders(response) }
                connection.send(content: nil, isComplete: true, completion: .contentProcessed { [weak self] _ in self?.finish() })
            }
            session.finishTasksAndInvalidate()
        }

        private func sendHeaders(_ response: HTTPURLResponse) {
            var header = "HTTP/1.1 \(response.statusCode) Media\r\nConnection: close\r\nCache-Control: no-store\r\n"
            for name in ["Content-Type", "Content-Length", "Content-Range", "Accept-Ranges"] {
                if let value = response.value(forHTTPHeaderField: name), !value.contains("\r"), !value.contains("\n") {
                    header += "\(name): \(value)\r\n"
                }
            }
            headersSent = true
            connection.send(content: Data((header + "\r\n").utf8), completion: .contentProcessed { [weak self] error in
                if error != nil { self?.cancel(); self?.finish() }
            })
        }

        private func fail() {
            guard !closed else { return }
            closed = true
            task?.cancel()
            session?.invalidateAndCancel()
            if headersSent { finish() }
            else {
                connection.send(content: Data("HTTP/1.1 502 Media unavailable\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".utf8),
                                completion: .contentProcessed { [weak self] _ in self?.finish() })
            }
        }
    }
}
