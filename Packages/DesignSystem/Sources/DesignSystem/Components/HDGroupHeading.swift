import SwiftUI

public struct HDGroupHeading: View {
    private let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        HDText(title, style: HDType.bodyStrong, color: .hdInk)
            .accessibilityAddTraits(.isHeader)
    }
}
