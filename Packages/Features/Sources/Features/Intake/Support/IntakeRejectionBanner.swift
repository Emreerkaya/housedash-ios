import DesignSystem
import SwiftUI

struct IntakeRejectionBanner: View {
    let rejection: DescriptionRejection

    var body: some View {
        HStack(alignment: .top, spacing: HDSpacing.item) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.hdAlert)
                .accessibilityHidden(true)
            HDText(rejection.summary, style: HDType.caption, color: .hdAlert)
        }
        .padding(14)
        .background(Color.hdSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hdAlert, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
