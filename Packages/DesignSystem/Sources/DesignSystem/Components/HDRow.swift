import SwiftUI

public struct HDRow<Thumb: View>: View {
    private let thumb: Thumb
    private let primary: String
    private let secondary: String
    private let meta: String?
    private let trailing: String?

    public init(
        primary: String,
        secondary: String,
        meta: String? = nil,
        trailing: String? = nil,
        @ViewBuilder thumb: () -> Thumb
    ) {
        self.thumb = thumb()
        self.primary = primary
        self.secondary = secondary
        self.meta = meta
        self.trailing = trailing
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            thumb
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HDText(primary, style: HDType.bodyStrong, color: .hdInk)
                HDText(secondary, style: HDType.factRow, color: .hdInkSoft)
                if let meta {
                    HDText(meta, style: HDType.caption, color: .hdInkFaint)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let trailing {
                HDText(trailing, style: HDType.caption, color: .hdInkFaint)
            }
        }
        .padding(.vertical, 14)
    }
}
