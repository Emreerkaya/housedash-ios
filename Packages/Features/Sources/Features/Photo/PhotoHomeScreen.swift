import SwiftUI
import DesignSystem

public struct PhotoHomeScreen<TabBar: View>: View {
    @State private var model = PhotoFirstFlowModel()
    private let tabBar: TabBar

    public init(@ViewBuilder tabBar: () -> TabBar) {
        self.tabBar = tabBar()
    }

    public var body: some View {
        HDTabScreen(tab: .photo) {
            NavigationStack(path: $model.path) {
                B05PhotoScreen(model: model, tabBar: tabBar)
                    .navigationBarBackButtonHidden(true)
                    .navigationDestination(for: PhotoFirstRoute.self) { route in
                        destination(for: route)
                            .navigationBarBackButtonHidden(true)
                    }
                    .overlay(alignment: .top) {
                        if let description = model.completedDescription {
                            completionNotice(description)
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: PhotoFirstRoute) -> some View {
        switch route {
        case .aFewDetails:
            B07AFewDetailsScreen(model: model)
        }
    }

    private func completionNotice(_ description: Description) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HDText("Case ready: \"\(description.text)\"", style: HDType.bodyStrong, color: .hdOnContext)
            HDText(
                "Comparing the DIY guide against nearby people isn't built yet — that's next.",
                style: HDType.caption,
                color: .hdOnContext
            )
            Button("Got it") {
                model.acknowledgeCompletion()
            }
            .buttonStyle(.plain)
            .frame(minHeight: 44)
            .hdTypeStyle(HDType.label)
            .foregroundStyle(Color.hdOnContext)
            .accessibilityAddTraits(.isButton)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.hdContext, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(HDSpacing.margin)
    }
}
