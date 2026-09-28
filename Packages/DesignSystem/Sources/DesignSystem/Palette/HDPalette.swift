public struct HDColorPair: Sendable, Equatable {
    public let light: String
    public let dark: String

    public init(light: String, dark: String) {
        self.light = light
        self.dark = dark
    }
}

public enum HDPalette {
    public static let pairs: [HDToken: HDColorPair] = [
        .ground: HDColorPair(light: "#E3DCD6", dark: "#25211E"),
        .surface: HDColorPair(light: "#F7F3F0", dark: "#302B28"),
        .surfaceSunk: HDColorPair(light: "#D9D0C9", dark: "#3A3430"),
        .ink: HDColorPair(light: "#2F2829", dark: "#EDE7E3"),
        .inkSoft: HDColorPair(light: "#4B413B", dark: "#C6BBB3"),
        .inkFaint: HDColorPair(light: "#605955", dark: "#A39C97"),
        .hairline: HDColorPair(light: "#BDB4AE", dark: "#443D39"),
        .locked: HDColorPair(light: "#C7C0BA", dark: "#4D4845"),
        .accentDIY: HDColorPair(light: "#936725", dark: "#DDAA69"),
        .accentHire: HDColorPair(light: "#5B6DA7", dark: "#A2B1EC"),
        .alert: HDColorPair(light: "#BC3F3D", dark: "#F27A72"),
        .held: HDColorPair(light: "#6B7074", dark: "#A0A7AC"),
        .verified: HDColorPair(light: "#326441", dark: "#74A981"),
        .onAccent: HDColorPair(light: "#F7F3F0", dark: "#25211E"),
        .context: HDColorPair(light: "#2F2829", dark: "#1B1714"),
        .onContext: HDColorPair(light: "#F7F3F0", dark: "#EDE7E3")
    ]

    public static func pair(for token: HDToken) -> HDColorPair {
        guard let pair = pairs[token] else {
            preconditionFailure("Missing generated color pair for \(token)")
        }
        return pair
    }
}
