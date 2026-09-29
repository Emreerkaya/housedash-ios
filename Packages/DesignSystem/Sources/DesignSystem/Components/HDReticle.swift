import SwiftUI

public struct HDReticleGeometry: Equatable, Sendable {
    public let armLength: CGFloat
    public let thickness: CGFloat
    public let bars: [CGRect]
}

public struct HDReticle: View {
    public static let nativeSize: CGFloat = 220

    private static let armRatio: CGFloat = 42.0 / 220.0
    private static let thicknessRatio: CGFloat = 3.0 / 220.0

    public init() {}

    public static func geometry(for size: CGSize) -> HDReticleGeometry {
        let side = min(size.width, size.height)
        let arm = side * armRatio
        let thickness = side * thicknessRatio
        let w = size.width
        let h = size.height

        let bars: [CGRect] = [
            CGRect(x: 0, y: 0, width: arm, height: thickness),
            CGRect(x: 0, y: 0, width: thickness, height: arm),

            CGRect(x: w - arm, y: 0, width: arm, height: thickness),
            CGRect(x: w - thickness, y: 0, width: thickness, height: arm),

            CGRect(x: 0, y: h - thickness, width: arm, height: thickness),
            CGRect(x: 0, y: h - arm, width: thickness, height: arm),

            CGRect(x: w - arm, y: h - thickness, width: arm, height: thickness),
            CGRect(x: w - thickness, y: h - arm, width: thickness, height: arm)
        ]

        return HDReticleGeometry(armLength: arm, thickness: thickness, bars: bars)
    }

    public var body: some View {
        GeometryReader { proxy in
            let geometry = Self.geometry(for: proxy.size)
            ForEach(geometry.bars.indices, id: \.self) { index in
                let bar = geometry.bars[index]
                Rectangle()
                    .fill(Color.hdOnContext)
                    .frame(width: bar.width, height: bar.height)
                    .offset(x: bar.minX, y: bar.minY)
            }
        }
        .frame(idealWidth: Self.nativeSize, idealHeight: Self.nativeSize)
    }
}
