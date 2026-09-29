import SwiftUI
import DesignSystem

public struct ToolboxHomeScreen: View {
    public enum Focus: Hashable, Sendable {
        case saved
        case doneMyself
    }

    static func heading(for focus: Focus) -> String {
        switch focus {
        case .saved: "No guides saved yet"
        case .doneMyself: "Nothing marked done yet"
        }
    }

    static func message(for focus: Focus) -> String {
        switch focus {
        case .saved:
            "Save a guide from any repair you look at and it stays here, ready the next time the same thing breaks."
        case .doneMyself:
            "Finish a repair yourself from a guide and it moves here, with what it took and how long it ran."
        }
    }

    static let supportLine =
        "Looking for a specific repair? [Message support](https://housedash.app/support) and we will help you find it."

    @State private var focus: Focus

    public init(initialFocus: Focus = .saved) {
        _focus = State(initialValue: initialFocus)
    }

    var emptyStateHeading: String { Self.heading(for: focus) }
    var emptyStateMessage: String { Self.message(for: focus) }

    public var body: some View {
        HDScreen {
            HDItemStack {
                HDText("Toolbox", style: HDType.titleLarge)
                HDText(
                    "Guides you have saved and the repairs you have already done yourself.",
                    style: HDType.body,
                    color: .hdInkSoft
                )
            }

            HDItemStack {
                HStack(spacing: HDSpacing.item) {
                    HDChip("Saved", state: focus == .saved ? .selected : .unselected) {
                        focus = .saved
                    }
                    HDChip("Done myself", state: focus == .doneMyself ? .selected : .unselected) {
                        focus = .doneMyself
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
