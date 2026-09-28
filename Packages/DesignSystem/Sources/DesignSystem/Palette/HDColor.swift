import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
public extension UIColor {
    convenience init(hdToken token: HDToken) {
        let pair = HDPalette.pair(for: token)
        guard
            let lightComponents = HDHexComponents(hex: pair.light),
            let darkComponents = HDHexComponents(hex: pair.dark)
        else {
            preconditionFailure("Malformed generated hex for \(token)")
        }
        self.init { traits in
            let components = traits.userInterfaceStyle == .dark ? darkComponents : lightComponents
            return UIColor(
                red: components.red,
                green: components.green,
                blue: components.blue,
                alpha: 1
            )
        }
    }
}
#endif

public extension Color {
    init(hdToken token: HDToken) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor(hdToken: token))
        #else
        let pair = HDPalette.pair(for: token)
        let components = HDHexComponents(hex: pair.light) ?? HDHexComponents(hex: "#000000")!
        self.init(.sRGB, red: components.red, green: components.green, blue: components.blue, opacity: 1)
        #endif
    }
}

public extension Color {
    static let hdGround = Color(hdToken: .ground)
    static let hdSurface = Color(hdToken: .surface)
    static let hdSurfaceSunk = Color(hdToken: .surfaceSunk)
    static let hdInk = Color(hdToken: .ink)
    static let hdInkSoft = Color(hdToken: .inkSoft)
    static let hdInkFaint = Color(hdToken: .inkFaint)
    static let hdHairline = Color(hdToken: .hairline)
    static let hdLocked = Color(hdToken: .locked)
    static let hdAccentDIY = Color(hdToken: .accentDIY)
    static let hdAccentHire = Color(hdToken: .accentHire)
    static let hdAlert = Color(hdToken: .alert)
    static let hdHeld = Color(hdToken: .held)
    static let hdVerified = Color(hdToken: .verified)
    static let hdOnAccent = Color(hdToken: .onAccent)
    static let hdContext = Color(hdToken: .context)
    static let hdOnContext = Color(hdToken: .onContext)
}
