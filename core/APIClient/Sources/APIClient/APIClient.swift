import Foundation
import Common
import UserStore

final public class APIClient {
    private var baseUrl: URL?
//    private let authorizationProvider = AuthorizationProvider()
    
    private let session = URLSession.shared
    
    /// Instantiate WebClient for RideBee server from Configuration.swift
    public convenience init() {
        self.init(baseUrl: Config.baseEndpointUrl)
    }
    
    /// Instantiate WebClient with given baseURL
    ///
    /// - Parameter baseUrl: A base URL of remote API
    init(baseUrl: URL?) {
        self.baseUrl = baseUrl
    }
    
    /// Send request to remote server
    ///
    /// - Parameters:
    ///   - request: A APIRequest object that provides HTTPmethod, path, data to send and type of response.
    ///   - jwtToken: An optional String to indicate if request should be performed with JWT Authorization or not
    ///   - completion: Completion handler to call when request is completed.
    private func sendRequest<T: APIRequest>(_ request: T, bearer: String? = nil) async -> Result<(T.Response, Int), APIClientError> {
        
        let endpoint = self.endpoint(for: request)
        var urlRequest = URLRequest(url: endpoint)
        
        urlRequest.httpMethod = request.method.description
        // urlRequests are not forcing to ignore cached data. That's why it might be possible to see older data. Also the statusCode 304 (send on server-side) will be changed to a 200. For more information see (https://stackoverflow.com/q/46696624)
        if let bearer =  bearer {
            urlRequest.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }
        
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
            
            if case 400..<600 = response.statusCode {
                let httpStatusCode = HTTPStatusCode(rawValue: response.statusCode)
                log.error("request \(urlRequest) failed: \(httpStatusCode ?? .unknown)")
                return .failure(.httpURLResponseError(statusCode: httpStatusCode))
            }
            
            /*
             If the response from the endpoint is not decodable and this is the expected behaviour
             (by specifying RawResponse as ResponseType in Request) return the raw response
            */
            if T.Response.self is RawResponse.Type {
                let rawData = String.init(data: data, encoding: String.Encoding.utf8)
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
    
    /// Wrapper for send request to remote server, if token is expired it will be refreshed before performing request
    ///
    /// - Parameters:
    ///   - request: A APIRequest object that provides HTTPmethod, path, data to send and type of response.
    ///   - completion: Completion handler to call when request is completed.
    public func send<T: APIRequest>(_ request: T) async -> Result<(T.Response, Int), APIClientError> {
        
        return await self.sendRequest(request, bearer: UserSession.shared.bearerToken)
        
        // TODO: implement retry mechanics
//        guard let token = UserSession.shared.bearerToken else {
//            // We have no jwt token, perform request without refresh logic
//            self.sendRequest(request, completion: completion)
//            return
//        }
        
        // When performing the refresh token request, we do not want to apply the token refresh logic
//        if request is AuthorizationProvider.LoginUser {
//            self.sendRequest(request, completion: completion)
//            return
//        }
//
//        authorizationProvider.getJWTToken { result in
//            switch result {
//            case .success(let token):
//                self.storeToken(token: token)
//                self.sendRequest(request, jwtToken: token) { result in
//                    switch result {
//                    case .success(let response):
//                        completion(.success(response))
//                    case .failure(let error):
//                        completion(.failure(error))
//                    }
//                }
//            case .failure(let error):
//                self.perfomLogout()
//                completion(.failure(error))
//            }
//        }
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
        
    private func perfomLogout() {
        log.debug("Logging user out because token could not be refreshed")
        DispatchQueue.main.async {
            UserSession.shared.saveBearerToken(token: nil, shouldRemember: false)
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

