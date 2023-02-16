import Foundation

struct HttpHeaders {
    static let Authorization = "Authorization"
    static let UserAgent = "User-Agent"
    static let Accept = "accept"
    static let ContentType = "Content-Type"
}

struct DefaultHttpHeaderValues {
    static let ArtemisUserAgent = "artemis-native-client"
}

struct ContentTypes {
    struct Application {
        static let Json = "application/json"
    }
}

extension URLRequest {

    /**
     * Set the http header field content type to application/json
     */
    mutating func contentTypeJson() {
        self.addValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    /**
     Set the Authorization header field to "Bearer: authToken"
     - Parameter authToken: the auth token without a leading "Bearer: "
     */
    mutating func bearerAuth(authToken: String) {
        self.addValue("Bearer: " + authToken, forHTTPHeaderField: "Authorization")
    }
}
