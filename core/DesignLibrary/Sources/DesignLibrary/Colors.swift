//
//  File.swift
//
//
//  Created by Sven Andabaka on 01.03.23.
//

import Foundation
import UIKit
import SwiftUI

public extension UIColor {

    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(netHex: Int) {
        self.init(red: (netHex >> 16) & 0xff, green: (netHex >> 8) & 0xff, blue: netHex & 0xff)
    }

    // swiftlint:disable identifier_name
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }

    /// Initializes a dynamic color that displays the appropriate color in light and dark mode (iOS).
    /// Only the dark mode color is displayed on watchOS as it does not have a light mode.
    /// - Parameters:
    ///   - lightModeColor: the color to be displayed in light mode
    ///   - darkModeColor: the color to be displayed in dark mode
    convenience init(_ lightModeColor: UIColor, darkModeColor: UIColor) {
        #if os(iOS)
        self.init(dynamicProvider: { (traitCollection: UITraitCollection) -> UIColor in
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                return lightModeColor
            case .dark:
                return darkModeColor
            @unknown default:
                return lightModeColor
            }
        })
        #else
        // watchOS does not have a "light" mode
        self.init(cgColor: darkModeColor.cgColor)
        #endif
    }
}

fileprivate extension UIColor {
    struct ColorPalette {
        static let White = UIColor(netHex: 0xffffff)
        static let Gray05 = UIColor(netHex: 0xf2f2f2)
        static let Gray10 = UIColor(netHex: 0xe6e6e6)
        static let Gray20 = UIColor(netHex: 0xcccccc)
        static let Gray30 = UIColor(netHex: 0xb3b3b3)
        static let Gray40 = UIColor(netHex: 0x999999)
        static let Gray50 = UIColor(netHex: 0x808080)
        static let Gray60 = UIColor(netHex: 0x666666)
        static let Gray70 = UIColor(netHex: 0x4d4d4d)
        static let Gray80 = UIColor(netHex: 0x333333)
        static let Gray90 = UIColor(netHex: 0x1a1a1a)
        static let Gray95 = UIColor(netHex: 0x0d0d0d)
        static let Black = UIColor(netHex: 0x000000)

        static let ArtemisBlue = UIColor(netHex: 0x3e8acc)
        static let ArtemisLightBlue = UIColor(netHex: 0xb5cee4)

        static let Red = UIColor(netHex: 0xdc3545)
        static let Orange = UIColor(netHex: 0xfd7e14)
        static let Yellow = UIColor(netHex: 0xffc107)
        static let Green = UIColor(netHex: 0x28a745)
    }
}

public extension Color {

    // MARK: Semantic Colors
    struct Artemis {

        // Primary Artemis Color
        public static let artemisBlue = UIColor.ColorPalette.ArtemisBlue.suColor
        public static let artemisLightBlue = UIColor.ColorPalette.ArtemisLightBlue.suColor

        // Text
        public static let primaryLabel = UIColor.label.suColor
        public static let secondaryLabel = UIColor(UIColor.ColorPalette.Gray80, darkModeColor: UIColor.ColorPalette.Gray20).suColor
        public static let infoLabel = UIColor(UIColor.ColorPalette.ArtemisBlue, darkModeColor: UIColor.ColorPalette.ArtemisBlue).suColor

        // Button
        public static let primaryButtonColor = UIColor.ColorPalette.ArtemisBlue.suColor
        public static let primaryButtonTextColor = UIColor.ColorPalette.White.suColor
        public static let secondaryButtonColor = UIColor.ColorPalette.ArtemisBlue.suColor
        public static let secondaryButtonTextColor = UIColor.ColorPalette.ArtemisBlue.suColor
        public static let buttonDisabledColor = UIColor.ColorPalette.Gray50.suColor

        // TextField
        public static let textFieldColor = UIColor(UIColor.ColorPalette.White, darkModeColor: UIColor.ColorPalette.Black).suColor.opacity(0.6)

        // Toggle
        public static let toggleColor = UIColor.ColorPalette.ArtemisBlue.suColor

        // Card Colors
        public static let cardBackgroundColor = UIColor(UIColor.ColorPalette.ArtemisLightBlue, darkModeColor: UIColor.ColorPalette.Gray80).suColor
        public static let modalCardBackgroundColor = UIColor(UIColor.ColorPalette.Gray10, darkModeColor: UIColor.ColorPalette.Gray80).suColor
        public static let dashboardCardBackgroundColor = UIColor(UIColor.ColorPalette.Gray10, darkModeColor: UIColor.ColorPalette.Gray90).suColor
        public static let cardBorderColor = UIColor(UIColor.ColorPalette.Gray20, darkModeColor: UIColor.ColorPalette.Gray80).suColor
        public static let exerciseCardBackgroundColor = UIColor(UIColor.ColorPalette.Gray05, darkModeColor: UIColor.ColorPalette.Gray80).suColor

        // Login
        public static let loginBackgroundColor = UIColor(UIColor.ColorPalette.White, darkModeColor: UIColor.ColorPalette.Gray80).suColor
        public static let loginTextFieldBorderColor = UIColor(UIColor.ColorPalette.Gray20, darkModeColor: UIColor.ColorPalette.Gray80).suColor

        // Result
        public static let resultFailedColor = UIColor.ColorPalette.Red.suColor
        public static let resultLateColor = UIColor(UIColor.ColorPalette.Gray60, darkModeColor: UIColor.ColorPalette.Gray40).suColor
        public static let resultPendingColor = UIColor(UIColor.ColorPalette.Gray60, darkModeColor: UIColor.ColorPalette.Gray40).suColor
        public static let resultSuccess = UIColor.ColorPalette.Green.suColor
        public static let resultSuccessBelowScore = UIColor.ColorPalette.Orange.suColor

        // Badges
        public static let badgeWarningColor = UIColor.ColorPalette.Yellow.suColor
        public static let badgeSuccessColor = UIColor.ColorPalette.Green.suColor
        public static let badgeDangerColor = UIColor.ColorPalette.Red.suColor
        public static let badgeSecondaryColor = UIColor.ColorPalette.Gray60.suColor

        // Course Score
        public static let courseScoreProgressBackgroundColor = UIColor.ColorPalette.Red.suColor
        public static let courseScoreProgressRingColor = UIColor.ColorPalette.Green.suColor

        // Message
        public static let reactionCapsuleColor = UIColor(UIColor.ColorPalette.Gray10, darkModeColor: UIColor.ColorPalette.Gray90).suColor
        public static let messsageCellPressed = UIColor(UIColor.ColorPalette.Gray05, darkModeColor: UIColor.ColorPalette.Gray95).suColor
    }
}

public extension UIColor {
    /// The SwiftUI color associated with the receiver.
    var suColor: Color { Color(self) }
}
