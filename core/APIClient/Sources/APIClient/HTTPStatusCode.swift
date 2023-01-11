//
//  File.swift
//  
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation

public enum HTTPStatusCode: Int {
    
    case unknown
    
    // 200 Success
    case ok = 200 // swiftlint:disable:this identifier_name
    
    // 400 Client Error
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    
    // 500 Server Error
    case internalServerError = 500
}
