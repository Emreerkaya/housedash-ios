import CoreText
import Foundation

public enum HDZillaSlab {
    public static let postScriptName = "ZillaSlab-SemiBold"

    public static let registerOnce: Bool = {
        guard let url = Bundle.module.url(forResource: "ZillaSlab-SemiBold", withExtension: "ttf") else {
            return false
        }
        var error: Unmanaged<CFError>?
        return CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    }()
}
