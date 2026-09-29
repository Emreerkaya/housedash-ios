import DesignSystem
import SwiftUI

struct B01FixScreen: View {
    @Bindable var model: IntakeFlowModel

    var body: some View {
        VStack(spacing: 0) {
            HDHeader(title: "What needs fixing?")
            HDScreen {
                if let description = model.completedDescription {
                    completionNotice(description)
                }
                rooms
                ForEach(model.rails) { rail in
                    HDItemStack {
                        railHeading(rail.heading)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(rail.cards) { card in
                                    IntakeCard(problem: card) {
                                        Task { await model.selectProblem(card) }
                                    }
                                }
                            }
                        }
                    }
                }
                if !model.isLoadingRails && model.rails.isEmpty {
                    HDText(
                        "Nothing curated for \(model.selectedRoom.label.lowercased()) yet — pick a problem from another room.",
                        style: HDType.caption,
                        color: .hdInkFaint
                    )
                }
            }
        }
        .background(Color.hdGround.ignoresSafeArea())
        .task(id: model.selectedRoom) {
            await model.loadRails()
        }
    }

    func railHeading(_ heading: String) -> some View {
        HDText(heading, style: HDType.bodyStrong, color: .hdInk)
    }

    private var rooms: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HDSpacing.item) {
                ForEach(model.rooms) { room in
                    HDChip(room.label, state: room == model.selectedRoom ? .selected : .unselected) {
                        Task { await model.selectRoom(room) }
                    }
                }
            }
        }
    }

    private func completionNotice(_ description: Description) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HDText("Case ready: \"\(description.text)\"", style: HDType.bodyStrong, color: .hdInk)
            HDText(
                "Comparing the DIY guide against nearby people isn't built yet — that's next.",
                style: HDType.caption,
                color: .hdInkSoft
            )
            Button("Got it") {
                model.acknowledgeCompletion()
            }
            .buttonStyle(.plain)
            .frame(minHeight: 44)
            .hdTypeStyle(HDType.label)
            .foregroundStyle(Color.hdInkSoft)
            .accessibilityAddTraits(.isButton)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.hdSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
