import SwiftUI

public struct HDTypeStyle: Sendable, Equatable {
    public enum Family: Sendable, Equatable {
        case system
        case zillaSlabSemiBold
    }

    public let size: CGFloat
    public let weight: Font.Weight
    public let tracking: CGFloat
    public let family: Family

    public init(size: CGFloat, weight: Font.Weight, tracking: CGFloat, family: Family = .system) {
        self.size = size
        self.weight = weight
        self.tracking = tracking
        self.family = family
    }

    public var font: Font {
        switch family {
        case .system:
            return .system(size: size, weight: weight)
        case .zillaSlabSemiBold:
            _ = HDZillaSlab.registerOnce
            return .custom(HDZillaSlab.postScriptName, size: size)
        }
    }
}

public enum HDType {
    public static let titleLarge = HDTypeStyle(size: 31, weight: .semibold, tracking: -0.6665, family: .zillaSlabSemiBold)
    public static let money = HDTypeStyle(size: 44, weight: .bold, tracking: -0.977)
    public static let headlineFigure = HDTypeStyle(size: 32, weight: .bold, tracking: -0.691)
    public static let quote = HDTypeStyle(size: 22, weight: .regular, tracking: -0.403)
    public static let title = HDTypeStyle(size: 22, weight: .bold, tracking: -0.403)
    public static let section = HDTypeStyle(size: 20, weight: .bold, tracking: -0.334)
    public static let body = HDTypeStyle(size: 17, weight: .regular, tracking: -0.218)
    public static let bodyStrong = HDTypeStyle(size: 17, weight: .semibold, tracking: -0.218)
    public static let label = HDTypeStyle(size: 15, weight: .semibold, tracking: -0.132)
    public static let factRow = HDTypeStyle(size: 15, weight: .regular, tracking: -0.132)
    public static let bodyDense = HDTypeStyle(size: 15, weight: .regular, tracking: -0.132)
    public static let caption = HDTypeStyle(size: 13, weight: .regular, tracking: -0.042)
    public static let chevron = HDTypeStyle(size: 30, weight: .regular, tracking: 0)
}

public extension View {
    func hdTypeStyle(_ style: HDTypeStyle) -> some View {
        self
            .font(style.font)
            .tracking(style.tracking)
    }
}
