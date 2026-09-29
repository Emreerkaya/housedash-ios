import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum HDBundledImageResolution: Equatable, Sendable {
    case found
    case missing
}

public enum HDBundledImage {
    public static func resolution(named name: String, in bundle: Bundle) -> HDBundledImageResolution {
        #if canImport(UIKit)
        UIImage(named: name, in: bundle, compatibleWith: nil) != nil ? .found : .missing
        #else
        .missing
        #endif
    }

    public static func image(named name: String, in bundle: Bundle) -> Image? {
        #if canImport(UIKit)
        guard let uiImage = UIImage(named: name, in: bundle, compatibleWith: nil) else { return nil }
        return Image(uiImage: uiImage)
        #else
        return nil
        #endif
    }
}
