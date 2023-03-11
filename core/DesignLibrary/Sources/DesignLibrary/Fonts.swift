//
//  File.swift
//  
//
//  Created by Sven Andabaka on 11.03.23.
//

import SwiftUI

public extension Font {
    static var customBody: Font {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return Font.custom("SF Pro", size: 17, relativeTo: .body)
        default:
            return Font.custom("SF Pro", size: 22, relativeTo: .body)
        }
    }
}
