import Foundation
import SwiftUI

public extension Color {
    init(hexValue: Int64) {
        let r = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
        let g = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
        let b = CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0
        let a = CGFloat(hexValue & 0x000000FF) / 255.0
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}