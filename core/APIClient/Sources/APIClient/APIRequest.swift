//
//  File.swift
//
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation
import Common
import UserStore

public protocol APIRequest: Codable {
    associatedtype Response: Decodable

    var resourceName: String { get }
    var method: HTTPMethod { get }
}

public struct MultipartFormDataRequest {
    private let boundary: String = UUID().uuidString
    private var httpBody = NSMutableData()
    let url: URL

    public init(path: String) {
        guard let baseUrl = UserSession.shared.institution?.baseURL,
              let url = URL(string: path, relativeTo: baseUrl) else {
            fatalError("Bad resourceName: \(path)")
        }
        self.url = url
    }

    public func addTextField(named name: String, value: String) {
        httpBody.append(textFormField(named: name, value: value))
    }

    private func textFormField(named name: String, value: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
        fieldString += "Content-Transfer-Encoding: 8bit\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        return fieldString
    }

    public func addDataField(named name: String, filename: String?, data: Data, mimeType: String) {
        httpBody.append(dataFormField(named: name, filename: filename, data: data, mimeType: mimeType))
    }

    private func dataFormField(named name: String,
                               filename: String?,
                               data: Data,
                               mimeType: String) -> Data {
        let fieldData = NSMutableData()

        fieldData.append("--\(boundary)\r\n")
        fieldData.append("Content-Disposition: form-data; name=\"\(name)\"\(filename != nil ? "; filename=\"\(filename!)\" " : "" )\r\n")
        fieldData.append("Content-Type: \(mimeType)\r\n")
        fieldData.append("\r\n")
        fieldData.append(data)
        fieldData.append("\r\n")

        return fieldData as Data
    }

    func asURLRequest() -> URLRequest {
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        httpBody.append("--\(boundary)--")
        request.httpBody = httpBody as Data
        return request
    }
}

public struct RawResponse: Decodable {
    let rawData: String
}

extension NSMutableData {
    func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
