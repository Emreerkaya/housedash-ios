import DesignSystem
import SwiftUI

struct B01FixScreen: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Bindable var model: IntakeFlowModel

    var body: some View {
        VStack(spacing: 0) {
            HDHeader(title: "What needs fixing?")
            HDScreen {
                if let submission = model.completedSubmission {
                    IntakeCaseReadyNotice(submission: submission, tone: .onSurface) {
                        model.acknowledgeCompletion()
                    }
                }
                rooms
                ForEach(model.rails) { rail in
                    HDItemStack {
                        railHeading(rail.heading)
                        railStack(rail)
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
        .hdAnnounce(model.announcement) { model.acknowledgeAnnouncement() }
        .task(id: model.selectedRoom) {
            await model.loadRails()
        }
    }

    func railHeading(_ heading: String) -> some View {
        HDGroupHeading(heading)
    }

    @ViewBuilder
    func railStack(_ rail: ProblemRail) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: HDSpacing.item) {
                cards(rail)
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: HDSpacing.item) {
                    cards(rail)
                }
            }
        }
    }

    @ViewBuilder
    private func cards(_ rail: ProblemRail) -> some View {
        ForEach(rail.cards) { card in
            IntakeCard(problem: card) {
                Task { await model.selectProblem(card) }
            }
        }
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
}
