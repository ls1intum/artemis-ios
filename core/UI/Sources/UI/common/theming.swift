import Foundation
import SwiftUI

public extension Color {
    static var outline: Color = Color("outline")

    static var primaryContainer = PrimaryContainer(
        primaryContainer: Color("primaryContainer"),
        surface: Color("primaryContainerSurface"),
        onSurface: Color("onPrimaryContainerSurface"),
        onPrimaryContainer: Color("onPrimaryContainer")
    )
}

public struct PrimaryContainer {
    public let primaryContainer: Color
    public let surface: Color
    public let onSurface: Color
    public let onPrimaryContainer: Color
}
