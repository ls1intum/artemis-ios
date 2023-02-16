import Foundation
import Common
import UserStore

// swiftlint:disable force_cast
public final class APIClient {
    private var baseUrl: URL?

    private let session = URLSession.shared

    /// Instantiate WebClient for Artemis server from Configuration.swift
    public convenience init() {
        self.init(baseUrl: Config.baseEndpointUrl)
    }

    /// Instantiate WebClient with given baseURL
    ///
    /// - Parameter baseUrl: A base URL of remote API
    init(baseUrl: URL?) {
        self.baseUrl = baseUrl
    }

    /// Send an Multipath/Form-Data request to remote server
    ///
    /// - Parameters:
    ///   - request: A MultipartFormDataRequest object that provides HTTPmethod, path, data to send and type of response.
    ///   - currentTry: A counter which try the current is, used for retry mechanism
    public func sendRequest<T: Decodable>(_ request: MultipartFormDataRequest, currentTry: Int = 1) async -> Result<(T, Int), APIClientError> {
        let urlRequest = request.asURLRequest()
        printRequest(urlRequest: urlRequest)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            self.printResponse(for: urlRequest, data: data, response: response, error: nil)

            guard let response = response as? HTTPURLResponse else {
                return .failure(.notHTTPResponse)
            }

            // retry if not authorized
            if currentTry <= 3 && response.statusCode == 401 {
                return await sendRequest(request, currentTry: currentTry + 1)
            }

            // logout
            if response.statusCode == 401 {
                perfomLogout()
                UserSession.shared.setTokenExpired(expired: true)
            }

            if case 400..<600 = response.statusCode {
                do {
                    let decoder = JSONDecoder()
                    let error = try decoder.decode(UserFacingError.self, from: data)
                    return .failure(.jhipsterError(error: error))
                } catch {
                    let httpStatusCode = HTTPStatusCode(rawValue: response.statusCode)
                    log.error("request \(urlRequest) failed: \(httpStatusCode ?? .unknown)")
                    return .failure(.httpURLResponseError(statusCode: httpStatusCode,
                                                          artemisError: response.value(forHTTPHeaderField: "X-artemisApp-error")))
                }
            }

            /*
             If the response from the endpoint is not decodable and this is the expected behaviour
             (by specifying RawResponse as ResponseType in Request) return the raw response
             */
            if T.self is RawResponse.Type {
                let rawData = String(data: data, encoding: .utf8)
                return .success((RawResponse(rawData: rawData ?? "") as! T, response.statusCode))
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let returnValue = try decoder.decode(T.self, from: data)
                return .success((returnValue, response.statusCode))
            } catch {
                log.error(error)
                return .failure(.decodingError(error: error, statusCode: response.statusCode))
            }
        } catch {
            self.printResponse(for: urlRequest, data: nil, response: nil, error: error)
            log.error("datatask error: \(error)")
            return .failure(.networkError(error: error))
        }
    }

    /// Send normal http request to remote server
    ///
    /// - Parameters:
    ///   - request: A APIRequest object that provides HTTPmethod, path, data to send and type of response.
    ///   - currentTry: A counter which try the current is, used for retry mechanism
    public func sendRequest<T: APIRequest>(_ request: T, currentTry: Int = 1) async -> Result<(T.Response, Int), APIClientError> {
        let endpoint = self.endpoint(for: request)
        var urlRequest = URLRequest(url: endpoint)

        urlRequest.httpMethod = request.method.description
        // urlRequests are not forcing to ignore cached data. That's why it might be possible to see older data. Also the statusCode 304 (send on server-side) will be changed to a 200. For more information see (https://stackoverflow.com/q/46696624)

        // NOTE: GET requests with body are never sent
        // thus, add body only for non-GET requests
        if request.method != .get {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = body(for: request)
        }
        printRequest(urlRequest: urlRequest)

        do {
            let (data, response) = try await session.data(for: urlRequest)
            self.printResponse(for: urlRequest, data: data, response: response, error: nil)

            guard let response = response as? HTTPURLResponse else {
                return .failure(.notHTTPResponse)
            }

            // retry if not authorized
            if currentTry < 3 && response.statusCode == 401 {
                return await sendRequest(request, currentTry: currentTry + 1)
            }

            // logout
            if response.statusCode == 401 {
                perfomLogout()
                UserSession.shared.setTokenExpired(expired: true)
            }

            if case 400..<600 = response.statusCode {
                do {
                    let decoder = JSONDecoder()
                    let error = try decoder.decode(UserFacingError.self, from: data)
                    return .failure(.jhipsterError(error: error))
                } catch {
                    let httpStatusCode = HTTPStatusCode(rawValue: response.statusCode)
                    log.error("request \(urlRequest) failed: \(httpStatusCode ?? .unknown)")
                    return .failure(.httpURLResponseError(statusCode: httpStatusCode, artemisError: response.value(forHTTPHeaderField: "X-artemisApp-error")))
                }
            }

            /*
             If the response from the endpoint is not decodable and this is the expected behaviour
             (by specifying RawResponse as ResponseType in Request) return the raw response
             */
            if T.Response.self is RawResponse.Type {
                let rawData = String(data: data, encoding: .utf8)
                return .success((RawResponse(rawData: rawData ?? "") as! T.Response, response.statusCode))
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let body = try decoder.decode(T.Response.self, from: data)
                return .success((body, response.statusCode))
            } catch {
                log.error(error)
                return .failure(.decodingError(error: error, statusCode: response.statusCode))
            }
        } catch {
            self.printResponse(for: urlRequest, data: nil, response: nil, error: error)
            log.error("datatask error: \(error)")
            return .failure(.networkError(error: error))
        }
    }

    // MARK: - Helpers

    /// Create finalURL
    private func endpoint<T: APIRequest>(for request: T) -> URL {
        guard let baseUrl = URL(string: request.resourceName, relativeTo: baseUrl) else {
            fatalError("Bad resourceName: \(request.resourceName)")
        }
        return baseUrl
    }

    /// Create urlencoded body
    private func body<T: APIRequest>(for request: T) -> Data? {
        var bodyData: Data
        let encoder = JSONEncoder()
        do {
            bodyData = try encoder.encode(request)
        } catch {
            log.error("Couldn't encode HTTPRequest.body. Body is nil for non-GET request")
            return nil
        }
        return bodyData
    }

    public func perfomLogout() {
        log.debug("Logging user out because token could not be refreshed")
        DispatchQueue.main.async {
            Task {
                await URLSession.shared.reset()
            }
            UserSession.shared.setUserLoggedIn(isLoggedIn: false, shouldRemember: false)
            UserSession.shared.savePassword(password: nil)
        }
    }
}

// MARK: - Logging
extension APIClient {
    private func printRequest(urlRequest: URLRequest) {
        log.verbose(
            """
            \n––––––––––––––––––––––––––––––––––––––––Request––––––––––––––––––––––––––––––––––––––––––
            \(urlRequest.httpMethod ?? "empty") \(urlRequest.url?.absoluteString ?? "empty")
            Body: \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "")
            Length: \(urlRequest.httpBody?.debugDescription ?? "0")
            Content-Type: \(urlRequest.value(forHTTPHeaderField: "Content-Type") ?? "unknown")
            –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––\n
            """)
    }

    private func printResponse(for urlRequest: URLRequest, data: Data?, response: URLResponse?, error: Error?) {
        let urlString = urlRequest.url?.absoluteString ?? "empty"
        if let error = error {
            log.error(
                """
                \n––––––––––––––––––––––––––––––––––––––Error––––––––––––––––––––––––––––––––––––––––––––––
                Call to \(urlString) failed!
                Error: \(error)
                –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––\n
                """)
        }
        if let response = response as? HTTPURLResponse {
            log.verbose(
                """
                \n––––––––––––––––––––––––––––––––––––––––Response–––––––––––––––––––––––––––––––––––––––––
                \(response.statusCode) \(urlString)
                Body: \(String(data: data ?? Data(), encoding: .utf8) ?? "empty")
                –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––\n
                """)
        }
    }
}
