import Foundation

/// Retain the current manifest graph, rather than every URL ever advertised.
/// Access is serialized on the proxy's main queue. Active fetch leases protect
/// resources removed by a rolling window until their bytes have finished sending.
final class LectureMediaResourceRegistry {
    struct Resource {
        let url: URL
        let role: LectureMediaResourceRole
        var children: Set<String> = []
        var active = 0
        var retainedBytes: Int { url.absoluteString.utf8.count + 512 }
    }
    private struct Key: Hashable { let url: URL; let role: LectureMediaResourceRole }
    private var resources: [String: Resource] = [:]
    private var identifiers: [Key: String] = [:]
    private var roots: Set<String> = []
    private var rooted: Set<String> = []
    private var bytes = 0
    private let byteBudget: Int

    init(byteBudget: Int = 64 * 1024 * 1024) { self.byteBudget = byteBudget }

    func addRoot(_ url: URL, role: LectureMediaResourceRole) throws -> String {
        let id = try register(url, role: role)
        roots.insert(id)
        rooted.insert(id)
        return id
    }

    func resource(_ id: String) -> Resource? { resources[id] }

    func acquire(_ id: String) -> Resource? {
        guard var resource = resources[id] else { return nil }
        resource.active += 1
        resources[id] = resource
        return resource
    }

    func release(_ id: String) {
        guard var resource = resources[id] else { return }
        resource.active = max(0, resource.active - 1)
        resources[id] = resource
        if resource.active == 0 && !rooted.contains(id) { reclaim() }
    }

    func rewrite(_ playlist: String, relativeTo base: URL, owner: String, localURL: (String) throws -> URL) throws -> String {
        guard let old = resources[owner] else { throw LectureMediaError.unavailable }
        var children: Set<String> = []
        do {
            let rewritten = try LectureMediaPlaylist.rewrite(playlist, relativeTo: base, mapResource: { url, role in
                let id = try register(url, role: role)
                children.insert(id)
                return try localURL(id)
            })
            resources[owner]?.children = children
            let retained = reachable(from: roots.union(resources.compactMap { $0.value.active > 0 ? $0.key : nil }))
            let retainedBytes = retained.reduce(0) { $0 + (resources[$1]?.retainedBytes ?? 0) }
            guard retainedBytes <= byteBudget else { throw LectureMediaError.unavailable }
            reclaim()
            return rewritten
        } catch {
            resources[owner]?.children = old.children
            reclaim()
            throw error
        }
    }

    func reset() {
        resources.removeAll(); identifiers.removeAll(); roots.removeAll(); rooted.removeAll(); bytes = 0
    }

    private func register(_ url: URL, role: LectureMediaResourceRole) throws -> String {
        guard LectureMediaSource.classify(url) != .invalid else { throw LectureMediaError.invalidURL }
        let key = Key(url: url, role: role)
        if let id = identifiers[key] { return id }
        let resource = Resource(url: url, role: role)
        // A manifest replacement briefly owns its old and new generation. The
        // committed graph must fit one budget; temporary registration fits two.
        guard resources.count < 250_000, bytes + resource.retainedBytes <= byteBudget * 2 else { throw LectureMediaError.unavailable }
        let suffix = url.pathExtension.lowercased()
        let mediaExtensions: Set<String> = ["mp4", "ts", "m4s", "aac", "mp3", "vtt"]
        let id = UUID().uuidString + (role == .playlist ? ".m3u8" : (mediaExtensions.contains(suffix) ? "." + suffix : ""))
        identifiers[key] = id
        resources[id] = resource
        bytes += resource.retainedBytes
        return id
    }

    private func reachable(from starting: Set<String>) -> Set<String> {
        var result: Set<String> = []
        var pending = Array(starting)
        while let id = pending.popLast() {
            guard result.insert(id).inserted, let resource = resources[id] else { continue }
            pending.append(contentsOf: resource.children)
        }
        return result
    }

    private func reclaim() {
        rooted = reachable(from: roots)
        let active = Set(resources.compactMap { $0.value.active > 0 ? $0.key : nil })
        let retained = rooted.union(reachable(from: active))
        let expired = resources.keys.filter { !retained.contains($0) }
        for id in expired {
            guard let resource = resources.removeValue(forKey: id) else { continue }
            identifiers.removeValue(forKey: Key(url: resource.url, role: resource.role))
            bytes -= resource.retainedBytes
        }
    }
}
