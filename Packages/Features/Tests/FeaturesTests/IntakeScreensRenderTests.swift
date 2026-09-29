import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import DesignSystem
@testable import Features

#if canImport(UIKit)
@MainActor
final class IntakeScreensRenderTests: XCTestCase {
    private static let contentWidth: CGFloat = 353
    private static let deviceWidth: CGFloat = 402
    private static let supportedWidths: [CGFloat] = [402, 375, 320]
    private static let pointsWCAGAsksForATouchTarget: CGFloat = 44
    private static let tallestAnUnstackedRowCanBe: CGFloat = 80

    private func measuredSize<V: View>(
        _ view: V,
        width: CGFloat = 393,
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> CGSize {
        let controller = UIHostingController(rootView: view.environment(\.dynamicTypeSize, dynamicTypeSize))
        return controller.sizeThatFits(in: CGSize(width: width, height: CGFloat.infinity))
    }

    private func idealWidth(_ text: String, style: HDTypeStyle, dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        measuredSize(HDText(text, style: style, color: .hdInk), width: 10_000, dynamicTypeSize: dynamicTypeSize).width
    }

    private func makeModel() -> IntakeFlowModel {
        let model = IntakeFlowModel(catalogue: FakeProblemCatalogue(), camera: FakeCamera())
        model.rails = [
            ProblemRail(
                id: "common-in-a-kitchen",
                heading: "Common in a kitchen",
                cards: [FakeProblemCatalogue.drippingTap, FakeProblemCatalogue.blockedDrain]
            )
        ]
        return model
    }

    private func makePhotoModel() -> PhotoFirstFlowModel {
        PhotoFirstFlowModel(camera: FakeCamera())
    }

    private func chosenRow() -> HDIdentityRow {
        let problem = FakeProblemCatalogue.drippingTap
        return HDIdentityRow(
            primary: problem.fullTitle,
            secondary: "\(problem.category) · \(problem.priceRange) typical",
            onChange: {}
        )
    }

    func testB01GrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(B01FixScreen(model: makeModel()), dynamicTypeSize: .large)
        let huge = measuredSize(B01FixScreen(model: makeModel()), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testB02GrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let model = makeModel()
        model.symptoms = FakeProblemCatalogue.drippingTapSymptoms
        let normal = measuredSize(B02PickProblemScreen(model: model), dynamicTypeSize: .large)
        let huge = measuredSize(B02PickProblemScreen(model: model), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testB03GrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let model = makeModel()
        model.selectedProblem = FakeProblemCatalogue.drippingTap
        let symptom = FakeProblemCatalogue.drippingTapSymptoms[0]
        let normal = measuredSize(B03DescribeItScreen(model: model, symptom: symptom), dynamicTypeSize: .large)
        let huge = measuredSize(B03DescribeItScreen(model: model, symptom: symptom), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testB04GrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(B04SomethingElseScreen(model: makeModel()), dynamicTypeSize: .large)
        let huge = measuredSize(B04SomethingElseScreen(model: makeModel()), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testB07GrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(B07AFewDetailsScreen(model: makePhotoModel()), dynamicTypeSize: .large)
        let huge = measuredSize(B07AFewDetailsScreen(model: makePhotoModel()), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testRejectionBannerGrowsAtLargestAccessibilitySizeOnB03() {
        let model = makeModel()
        model.selectedProblem = FakeProblemCatalogue.drippingTap
        model.descriptionText = "call me on 917-555-0199"
        model.submit()
        XCTAssertNotNil(model.rejection)
        let symptom = FakeProblemCatalogue.drippingTapSymptoms[0]

        let normal = measuredSize(B03DescribeItScreen(model: model, symptom: symptom), dynamicTypeSize: .large)
        let huge = measuredSize(B03DescribeItScreen(model: model, symptom: symptom), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testEveryComponentOnTheseScreensGrowsInIsolationAtTheLargestAccessibilitySize() {
        let rejection = DescriptionRejection(signals: [.phoneNumber])
        let measurements: [(String, CGSize, CGSize)] = [
            (
                "IntakeCard",
                measuredSize(
                    IntakeCard(problem: FakeProblemCatalogue.drippingTap, action: {}),
                    width: Self.contentWidth,
                    dynamicTypeSize: .large
                ),
                measuredSize(
                    IntakeCard(problem: FakeProblemCatalogue.drippingTap, action: {}),
                    width: Self.contentWidth,
                    dynamicTypeSize: .accessibility5
                )
            ),
            (
                "IntakeRejectionBanner",
                measuredSize(IntakeRejectionBanner(rejection: rejection), width: Self.contentWidth),
                measuredSize(
                    IntakeRejectionBanner(rejection: rejection),
                    width: Self.contentWidth,
                    dynamicTypeSize: .accessibility5
                )
            ),
            (
                "IntakePickRow",
                measuredSize(
                    IntakePickRow(symptom: FakeProblemCatalogue.drippingTapSymptoms[0], action: {}),
                    width: Self.contentWidth
                ),
                measuredSize(
                    IntakePickRow(symptom: FakeProblemCatalogue.drippingTapSymptoms[0], action: {}),
                    width: Self.contentWidth,
                    dynamicTypeSize: .accessibility5
                )
            ),
            (
                "chosen row",
                measuredSize(chosenRow(), width: Self.contentWidth),
                measuredSize(chosenRow(), width: Self.contentWidth, dynamicTypeSize: .accessibility5)
            ),
            (
                "B03 add tile",
                measuredSize(IntakePhotoTile(kind: .add(caption: "Add"), action: {}), width: 99),
                measuredSize(
                    IntakePhotoTile(kind: .add(caption: "Add"), action: {}),
                    width: 99,
                    dynamicTypeSize: .accessibility5
                )
            ),
            (
                "B07 add tile",
                measuredSize(
                    IntakePhotoTile(kind: .add(caption: "Add from your phone"), minimumHeight: 124, cornerRadius: 10),
                    width: 165
                ),
                measuredSize(
                    IntakePhotoTile(kind: .add(caption: "Add from your phone"), minimumHeight: 124, cornerRadius: 10),
                    width: 165,
                    dynamicTypeSize: .accessibility5
                )
            ),
            (
                "camera hint pill",
                measuredSize(cameraScreen().pill(cameraScreen().hint, minimumScaleFactor: nil), width: Self.contentWidth),
                measuredSize(
                    cameraScreen().pill(cameraScreen().hint, minimumScaleFactor: nil),
                    width: Self.contentWidth,
                    dynamicTypeSize: .accessibility5
                )
            ),
            (
                "HDField with a trailing token",
                measuredSize(whereField(), width: Self.contentWidth),
                measuredSize(whereField(), width: Self.contentWidth, dynamicTypeSize: .accessibility5)
            ),
            (
                "the B04 composer",
                measuredSize(composer(), width: Self.contentWidth),
                measuredSize(composer(), width: Self.contentWidth, dynamicTypeSize: .accessibility5)
            )
        ]

        for (name, normal, huge) in measurements {
            XCTAssertGreaterThan(
                huge.height, normal.height,
                "\(name) did not grow at accessibility5: \(normal) -> \(huge)"
            )
        }
    }

    func testNoPhotoTileIsEverShorterThanTheContentInsideIt() {
        let tiles: [(String, IntakePhotoTileKind, CGFloat, CGFloat)] = [
            ("B03 add tile", .add(caption: "Add"), 108, 99),
            ("B07 add tile", .add(caption: "Add from your phone"), 124, 165),
            ("B07 captured tile", .captured(timestampLabel: "11:24"), 124, 165),
            ("B07 captured tile with a dated label", .captured(timestampLabel: "Yesterday 11:24"), 124, 165)
        ]

        for (name, kind, declared, width) in tiles {
            for size in [DynamicTypeSize.large, .accessibility5] {
                let content = measuredSize(
                    IntakePhotoTile(kind: kind, minimumHeight: 0, cornerRadius: 10),
                    width: width,
                    dynamicTypeSize: size
                ).height
                let tile = measuredSize(
                    IntakePhotoTile(kind: kind, minimumHeight: declared, cornerRadius: 10),
                    width: width,
                    dynamicTypeSize: size
                ).height

                XCTAssertGreaterThanOrEqual(
                    tile, content,
                    "\(name) at \(size) is \(tile)pt around \(content)pt of content, so the content overflows it"
                )
                XCTAssertGreaterThanOrEqual(tile, declared, "\(name) at \(size) fell below its declared minimum")
            }
        }
    }

    func testAPhotoTileGrowsPastItsDeclaredMinimumWhenItsContentNeedsMore() {
        let b03 = measuredSize(
            IntakePhotoTile(kind: .add(caption: "Add"), action: {}),
            width: 99,
            dynamicTypeSize: .accessibility5
        )
        let b07 = measuredSize(
            IntakePhotoTile(kind: .add(caption: "Add from your phone"), minimumHeight: 124, cornerRadius: 10),
            width: 165,
            dynamicTypeSize: .accessibility5
        )
        XCTAssertGreaterThan(b03.height, 108, "the B03 tile still pins its content to 108pt")
        XCTAssertGreaterThan(b07.height, 124, "the B07 tile still pins its content to 124pt")
    }

    func testNoFixedWidthColumnIsNarrowerThanTheWidestWordItMustRender() {
        let cardWidth = measuredSize(
            IntakeCard(problem: FakeProblemCatalogue.drippingTap, action: {}),
            width: Self.contentWidth,
            dynamicTypeSize: .accessibility5
        ).width

        for title in ["Dishwasher", "Draught-seal", "Silicone", "$140–220"] {
            let needed = idealWidth(title, style: HDType.label, dynamicTypeSize: .accessibility5)
            XCTAssertGreaterThanOrEqual(
                cardWidth, needed,
                "a card \(cardWidth)pt wide cannot render '\(title)', which needs \(needed)pt, without breaking it mid-word"
            )
        }
    }

    func testTheHintPillStillFitsInsideThePreviewItSitsOn() {
        let pill = measuredSize(
            cameraScreen().pill(cameraScreen().hint, minimumScaleFactor: nil),
            width: Self.deviceWidth - 2 * HDSpacing.margin,
            dynamicTypeSize: .accessibility5
        )
        XCTAssertLessThan(
            pill.height + 2 * HDSpacing.margin,
            CameraCaptureScreen.minimumPreviewHeight,
            "the hint pill overflows the shortest preview it can be drawn on"
        )
    }

    func testTheCameraTitleFitsTheWidthItIsGivenAtTheLargestAccessibilitySize() {
        let available = Self.deviceWidth - 2 * CameraCaptureScreen.navigationTitleInset
        let needed = idealWidth("Show us the problem", style: HDType.bodyStrong, dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThanOrEqual(
            available, needed * 0.6,
            "the title cannot reach its 0.6 scale floor in \(available)pt, so it truncates"
        )
    }

    func testTheChosenRowStacksRatherThanSqueezingItsTitleIntoAColumnTooNarrowForOneWord() {
        XCTAssertTrue(
            HDIdentityRow.stacks(at: .accessibility5),
            "the chosen row does not stack at accessibility5, so the width computed below is not the width it gives its title"
        )
        for size in DynamicTypeSize.allCases where !size.isAccessibilitySize {
            XCTAssertFalse(
                HDIdentityRow.stacks(at: size),
                "the chosen row stacks at \(size), which is not an accessibility size, so the rule has been imported onto every screen that uses the row"
            )
        }
        for width in Self.supportedWidths {
            let stacked = measuredSize(chosenRow(), width: width, dynamicTypeSize: .accessibility5)
            let flat = measuredSize(chosenRow(), width: width, dynamicTypeSize: .large)
            XCTAssertGreaterThan(
                stacked.height, flat.height,
                "at \(width)pt the row is \(stacked.height)pt at accessibility5 and \(flat.height)pt at the default size"
            )
            XCTAssertLessThan(
                flat.height, Self.tallestAnUnstackedRowCanBe,
                "at \(width)pt the row is \(flat.height)pt at the default content size, which is taller than a row with its affordance beside the text can be, so it is stacking where it should not"
            )
            let available = width - 2 * HDIdentityRow.horizontalPadding
            for word in ["Dripping", "faucet"] {
                let needed = idealWidth(word, style: HDType.bodyStrong, dynamicTypeSize: .accessibility5)
                XCTAssertGreaterThanOrEqual(
                    available, needed,
                    "'\(word)' needs \(needed)pt and the stacked row offers \(available)pt at \(width)pt, so it breaks mid-word"
                )
            }
        }
    }

    func testThePickRowGivesItsTitleTheWholeRowAtEveryWidthItShipsOn() {
        XCTAssertTrue(
            IntakePickRow.stacks(at: .accessibility5),
            "the pick row keeps its price beside its title at accessibility5, so the width below is not the width the title gets"
        )
        XCTAssertFalse(
            IntakePickRow.stacks(at: .large),
            "the pick row stacks at the default size too, which is not what it is drawn as"
        )
        let longestWord = ["constantly", "Dripping", "Worse"]
            .map { (word: $0, needed: idealWidth($0, style: HDType.bodyStrong, dynamicTypeSize: .accessibility5)) }
            .max { $0.needed < $1.needed }
        guard let longestWord else { return XCTFail("no word to measure") }
        for width in Self.supportedWidths {
            let available = width - 2 * IntakePickRow.horizontalPadding
            XCTAssertGreaterThanOrEqual(
                available, longestWord.needed,
                "'\(longestWord.word)' needs \(longestWord.needed)pt at accessibility5 and a \(width)pt row offers its title \(available)pt, so it breaks mid-word"
            )
        }
    }

    func testThePickRowsPriceIsNoLongerWhatBuysItsTitleALine() {
        let price = idealWidth("$90\u{2013}140", style: HDType.factRow, dynamicTypeSize: .accessibility5)
        for width in Self.supportedWidths {
            let available = width - 2 * IntakePickRow.horizontalPadding
            let sideBySide = available - price - HDSpacing.item
            let needed = idealWidth("constantly", style: HDType.bodyStrong, dynamicTypeSize: .accessibility5)
            XCTAssertLessThan(
                sideBySide, needed,
                "at \(width)pt the title would still have \(sideBySide)pt beside a \(price)pt price, so stacking is not what is keeping 'constantly' whole and this test is not measuring the fix"
            )
        }
    }

    func testEveryGroupHeadingGoesThroughTheOneComponentThatCarriesTheHeaderTrait() {
        let screen = B01FixScreen(model: makeModel())
        XCTAssertTrue(
            String(describing: type(of: screen.railHeading("Common in a kitchen"))).contains("HDGroupHeading"),
            "a rail heading drawn as bare text is invisible to the heading rotor"
        )
        XCTAssertEqual(
            HDToken.tokens(in: .text).isEmpty, false,
            "the palette reports no text tokens, so the heading colour below is not a colour"
        )
    }

    func testTheFlashAffordanceIsNoLongerAControlAtAll() {
        let camera = cameraScreen()
        XCTAssertFalse(
            String(describing: type(of: camera.flashIndicator)).contains("Button"),
            "the flash is a Button again, and it still cannot do anything"
        )
    }

    func testThePhotoCountBadgeResolvesToSomethingVisibleOnTheCircleItDraws() throws {
        let badge = HDCountBadge(count: 1, on: CameraCaptureScreen.photoCountBadgeCircle)
        let ink = try XCTUnwrap(
            badge.ink,
            "no token in the palette clears AA on \(CameraCaptureScreen.photoCountBadgeCircle) in both bands, so the badge has nothing legible to draw with"
        )
        let resolvedInk = UIColor(Color(hdToken: ink))
        let resolvedCircle = UIColor(Color(hdToken: CameraCaptureScreen.photoCountBadgeCircle))
        for style in [UIUserInterfaceStyle.light, .dark] {
            let trait = UITraitCollection(userInterfaceStyle: style)
            XCTAssertNotEqual(
                resolvedInk.resolvedColor(with: trait),
                resolvedCircle.resolvedColor(with: trait),
                "the badge resolves to the same value as the circle it sits on in \(style == .dark ? "dark" : "light"), so it is a blank dot"
            )
        }
        for band in HDBand.allCases {
            let ratio = HDContrast.ratio(of: ink, on: CameraCaptureScreen.photoCountBadgeCircle, in: band)
            XCTAssertGreaterThanOrEqual(
                ratio, HDCountBadge.wcagAAForBodyText,
                "the count the badge actually draws is \(String(format: "%.2f", ratio)):1 on its own circle in \(band)"
            )
        }
    }

    func testChangeAffordanceOnTheChosenRowMeetsTheFortyFourPointTouchTarget() {
        let button = measuredSize(chosenRow().changeButton, width: Self.contentWidth)
        XCTAssertGreaterThanOrEqual(
            button.height, Self.pointsWCAGAsksForATouchTarget,
            "the Change button is \(button.height)pt tall on its own, whatever the row around it measures"
        )
        XCTAssertGreaterThanOrEqual(
            button.width, Self.pointsWCAGAsksForATouchTarget,
            "the Change button is \(button.width)pt wide on its own"
        )
    }

    func testEveryTappableRowClearsFortyFourPointsAtTheSmallestContentSize() {
        let tiles: [(String, CGSize)] = [
            ("the add-photo tile", measuredSize(
                IntakePhotoTile(kind: .add(caption: "Add"), action: {}),
                width: 99,
                dynamicTypeSize: .xSmall
            )),
            ("a rail card", measuredSize(
                IntakeCard(problem: FakeProblemCatalogue.drippingTap, action: {}),
                dynamicTypeSize: .xSmall
            )),
            ("a pick row", measuredSize(
                IntakePickRow(symptom: FakeProblemCatalogue.drippingTapSymptoms[0], action: {}),
                dynamicTypeSize: .xSmall
            ))
        ]
        for (name, size) in tiles {
            XCTAssertGreaterThanOrEqual(
                size.height, Self.pointsWCAGAsksForATouchTarget,
                "\(name) is \(size.height)pt tall at the smallest content size, where nothing inside it is padding the target out"
            )
        }
    }

    private func cameraScreen() -> CameraCaptureScreen {
        CameraCaptureScreen(
            chrome: .tabRoot(title: "Show us the problem", onReview: {}),
            capturedCount: 0,
            isCaptureAvailable: true,
            onCapture: {}
        )
    }

    private func whereField() -> HDField<EmptyView> {
        HDField(
            label: "Where",
            placeholder: "Greenwich Village, 10012",
            text: .constant(""),
            trailing: HDRoom.kitchen.label
        )
    }

    private func composer() -> HDField<EmptyView> {
        HDField(
            label: "In your own words",
            placeholder: "The radiator in the back bedroom never gets hot, even with the valve fully open.",
            text: .constant(""),
            axis: .vertical,
            showsLabel: false,
            minimumVisibleLines: 4
        )
    }
}
#endif
