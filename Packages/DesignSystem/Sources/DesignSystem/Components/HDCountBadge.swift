import SwiftUI

public struct HDCountBadge: View {
    public static let wcagAAForBodyText: Double = 4.5

    public static func ink(on background: HDToken) -> HDToken? {
        HDToken.allCases.first { token in
            HDBand.allCases.allSatisfy { band in
                HDContrast.ratio(of: token, on: background, in: band) >= wcagAAForBodyText
            }
        }
    }

    private let count: Int
    private let background: HDToken

    public init(count: Int, on background: HDToken) {
        self.count = count
        self.background = background
    }

    public var ink: HDToken? { Self.ink(on: background) }

    public var body: some View {
        HDText("\(count)", style: HDType.caption, color: Color(hdToken: ink ?? background))
            .padding(4)
            .background(Color(hdToken: background), in: Circle())
    }
}
