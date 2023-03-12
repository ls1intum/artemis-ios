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
            guard let value else {
                self = .custom(nil)
                return
            }
            self = .custom(URL(string: value))
        }
    }

    public var name: String {
        switch self {
        case .tum:
            return R.string.localizable.nameTum()
        case .kit:
            return R.string.localizable.nameKit()
        case .codeability:
            return R.string.localizable.nameCodeAbility()
        case .hochschuleMuenchen:
            return R.string.localizable.nameHm()
        case .custom(let url):
            return url?.absoluteString ?? R.string.localizable.customInstance()
        }
    }

    public var shortName: String {
        switch self {
        case .tum:
            return R.string.localizable.nicknameTum()
        case .kit:
            return R.string.localizable.nicknameKit()
        case .hochschuleMuenchen:
            return R.string.localizable.nicknameHm()
        case .codeability:
            return R.string.localizable.nicknameCodeAbility()
        case .custom(let url):
            return url?.absoluteString ?? R.string.localizable.customInstance()
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

extension InstitutionIdentifier: Codable { }
