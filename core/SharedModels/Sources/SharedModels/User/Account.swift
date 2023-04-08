public struct Account: Codable {
    public let id: Int64
    public let login: String
    public let name: String
    public let firstName: String
    public let email: String
    public let langKey: String
}

public typealias User = Account
