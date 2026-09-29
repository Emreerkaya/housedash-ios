import Foundation

public enum HDBand: String, CaseIterable, Sendable {
    case light
    case dark
}

public extension HDColorPair {
    func hex(in band: HDBand) -> String {
        switch band {
        case .light: light
        case .dark: dark
        }
    }
}

public enum HDContrast {
    public static func ratio(of foreground: HDToken, on background: HDToken, in band: HDBand) -> Double {
        let first = relativeLuminance(of: HDPalette.pair(for: foreground).hex(in: band))
        let second = relativeLuminance(of: HDPalette.pair(for: background).hex(in: band))
        let lighter = max(first, second)
        let darker = min(first, second)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func relativeLuminance(of hex: String) -> Double {
        guard let components = HDHexComponents(hex: hex) else {
            preconditionFailure("Malformed generated hex \(hex)")
        }
        let channels = [components.red, components.green, components.blue].map(linearise)
        return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
    }

    private static func linearise(_ channel: Double) -> Double {
        channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }
}
