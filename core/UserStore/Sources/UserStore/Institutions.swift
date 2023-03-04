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
    case codeability
    case hochschuleMuenchen
    case custom(URL?)

    public static var allCases: [InstitutionIdentifier] {
        return [.tum, .kit, .codeability, .hochschuleMuenchen, .custom(nil)]
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
        case .hochschuleMuenchen:
            return "hm"
        case .codeability:
            return "codeability"
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
        case "hm":
            self = .hochschuleMuenchen
        case "codeability":
            self = .codeability
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
        case .codeability:
            return "codeAbility"
        case .hochschuleMuenchen:
            return "Hochschule München"
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
        case .hochschuleMuenchen:
            return "HM"
        case .codeability:
            return "codeAbility"
        case .custom(let url):
            return url?.absoluteString ?? "Custom Instance"
        }
    }

    public var baseURL: URL? {
        switch self {
        case .tum:
            return Config.tumBaseEndpointUrl
        case .kit:
            return Config.kitBaseEndpointUrl
        case .hochschuleMuenchen:
            return Config.hmBaseEndpointUrl
        case .codeability:
            return Config.codeAbilityBaseEndpointUrl
        case .custom(let url):
            return url
        }
    }

}

extension InstitutionIdentifier: Equatable { }
