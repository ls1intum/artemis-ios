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