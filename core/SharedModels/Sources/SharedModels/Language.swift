//
//  File.swift
//  
//
//  Created by Sven Andabaka on 11.03.23.
//

import Foundation

// swiftlint:disable identifier_name
public enum Language: String, RawRepresentable, Codable, Identifiable, Hashable {

    public var id: String {
        self.rawValue
    }

    case en, de

    public static var currentLanguage: Language {
        switch Locale.current.language.languageCode?.identifier {
        case "en": return .en
        case "de": return .de
        default: return .en
        }
    }
}
