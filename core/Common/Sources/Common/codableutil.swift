import Foundation

public extension Encodable {
    func asData(encoder: JSONEncoder) throws -> Data {
        try encoder.encode(self)
    }
}

public extension Data {
    func parseJson<T>(_ type: T.Type, _ decoder: JSONDecoder) throws -> T where T : Decodable {
        try decoder.decode(type, from: self)
    }
}