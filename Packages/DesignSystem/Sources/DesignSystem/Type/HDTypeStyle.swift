import SwiftUI

public struct HDTypeStyle: Sendable, Equatable {
    public let size: CGFloat
    public let weight: Font.Weight
    public let tracking: CGFloat

    public init(size: CGFloat, weight: Font.Weight, tracking: CGFloat) {
        self.size = size
        self.weight = weight
        self.tracking = tracking
    }
}

public enum HDType {
    public static let titleLarge = HDTypeStyle(size: 31, weight: .semibold, tracking: -0.666)
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
}

public extension View {
    func hdTypeStyle(_ style: HDTypeStyle) -> some View {
        self
            .font(.system(size: style.size, weight: style.weight, design: .default))
            .tracking(style.tracking)
    }
}
