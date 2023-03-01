//
//  File.swift
//  
//
//  Created by Sven Andabaka on 01.03.23.
//

import Foundation

public enum InstitutionIdentifier: CaseIterable, Identifiable {

    case tum
    case kit
    case custom(URL?)

    public static var allCases: [InstitutionIdentifier] {
        return [.tum, .kit, .custom(nil)]
    }

    public var id: String {
        value
    }

    var value: String {
        switch self {
        case .tum:
            return "tum"
        case .kit:
            return "kit"
        case .custom(let url):
            return url?.absoluteString ?? "nil"
        }
    }

    init(value: String?) {
        switch value {
        case "tum":
            self = .tum
        case "kit":
            self = .kit
        default:
            guard let value = value else {
                self = .custom(nil)
                return
            }
            self = .custom(URL(string: value))
        }
    }

    public var name: String {
        switch self {
        case .tum:
            return "Technical University of Munich"
        case .kit:
            return "Karlsruhe Institute of Technology"
        case .custom(let url):
            return url?.absoluteString ?? "Custom Instance"
        }
    }

    public var shortName: String {
        switch self {
        case .tum:
            return "TUM"
        case .kit:
            return "KIT"
        case .custom(let url):
            return url?.absoluteString ?? "Custom Instance"
        }
    }


}
