import SwiftUI
import DesignSystem

public struct JobsHomeScreen: View {
    public enum Filter: Hashable, Sendable {
        case upcoming
        case past
    }

    static func heading(for filter: Filter) -> String {
        switch filter {
        case .upcoming: "Nothing scheduled yet"
        case .past: "Nothing finished yet"
        }
    }

    static func message(for filter: Filter) -> String {
        switch filter {
        case .upcoming:
            "Once you choose to have someone do a fix, the booking lands here with the technician, the time, and a way to message them."
        case .past:
            "Every repair someone finishes for you keeps its record here, receipt included, so you can find it again later."
        }
    }

    static let supportLine =
        "Need someone today? [Message support](https://housedash.app/support) and we will point you the right way."

    @State private var filter: Filter

    public init(initialFilter: Filter = .upcoming) {
        _filter = State(initialValue: initialFilter)
    }

    var emptyStateHeading: String { Self.heading(for: filter) }
    var emptyStateMessage: String { Self.message(for: filter) }

    public var body: some View {
        HDScreen {
            HDItemStack {
                HDText("Jobs", style: HDType.titleLarge)
                HDText(
                    "Everything you have booked, scheduled, or hired out, in one place.",
                    style: HDType.body,
                    color: .hdInkSoft
                )
            }

            HDItemStack {
                HStack(spacing: HDSpacing.item) {
                    HDChip("Upcoming", state: filter == .upcoming ? .selected : .unselected) {
                        filter = .upcoming
                    }
                    HDChip("Past", state: filter == .past ? .selected : .unselected) {
                        filter = .past
                    }
                }

                HDGroupHeading(emptyStateHeading)
                HDText(emptyStateMessage, style: HDType.bodyDense, color: .hdInkFaint)
            }

            HDItemStack {
                Text(LocalizedStringKey(Self.supportLine))
                    .hdTypeStyle(HDType.caption)
                    .foregroundStyle(Color.hdInkFaint)
                    .tint(Color.hdInk)
            }
        }
    }
}
