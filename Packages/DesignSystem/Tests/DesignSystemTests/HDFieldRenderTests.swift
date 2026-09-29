import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

#if canImport(UIKit)
@MainActor
final class HDFieldRenderTests: XCTestCase {
    private static let contentWidth: CGFloat = 344
    private static let shortPrompt = "Drips"
    private static let longPrompt = "Drips constantly, worse when hot"
    private static let oneAccessibilityLine: CGFloat = 100
    private static let twoDefaultLines: CGFloat = 40

    private func height(
        placeholder: String,
        axis: Axis = .horizontal,
        minimumVisibleLines: Int = 1,
        at contentSize: UIContentSizeCategory
    ) -> CGFloat {
        var text = ""
        let field = HDField(
            label: "What is it doing?",
            placeholder: placeholder,
            text: Binding(get: { text }, set: { text = $0 }),
            axis: axis,
            minimumVisibleLines: minimumVisibleLines
        )
        let controller = UIHostingController(rootView: field)
        controller.traitOverrides.preferredContentSizeCategory = contentSize
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: Self.contentWidth, height: 1200))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        return controller.sizeThatFits(
            in: CGSize(width: Self.contentWidth, height: .greatestFiniteMagnitude)
        ).height
    }

    func testTheBoxIsSizedForThePromptItWillDisplayAtTheLargestContentSize() {
        let short = height(placeholder: Self.shortPrompt, at: .accessibilityExtraExtraExtraLarge)
        let long = height(placeholder: Self.longPrompt, at: .accessibilityExtraExtraExtraLarge)
        XCTAssertGreaterThan(
            long, short,
            "'\(Self.longPrompt)' and '\(Self.shortPrompt)' give the same \(short)pt box at the largest content size, so the prompt is not being drawn at the content size the box is"
        )
    }

    func testThePromptFitsOnOneLineAtTheDefaultContentSize() {
        let short = height(placeholder: Self.shortPrompt, at: .large)
        let long = height(placeholder: Self.longPrompt, at: .large)
        XCTAssertEqual(
            long, short, accuracy: 0.01,
            "'\(Self.longPrompt)' needs more than one line at the default content size, which is a copy problem rather than a scaling one"
        )
    }

    func testThePromptWrapsOntoFurtherLinesRatherThanBeingDrawnSmall() {
        let short = height(placeholder: Self.shortPrompt, at: .accessibilityExtraExtraExtraLarge)
        let long = height(placeholder: Self.longPrompt, at: .accessibilityExtraExtraExtraLarge)
        XCTAssertGreaterThan(
            long - short, Self.oneAccessibilityLine,
            "'\(Self.longPrompt)' buys the box only \(long - short)pt over '\(Self.shortPrompt)', which is less than one line at the largest content size, so it is being drawn smaller than the box it sits in"
        )
    }

    func testAHorizontalFieldStopsBeingOneLineAtAccessibilitySizes() {
        XCTAssertFalse(
            HDField<EmptyView>.wraps(at: .large, axis: .horizontal),
            "a horizontal field wraps at the default content size, so it is no longer a single-line field anywhere"
        )
        XCTAssertTrue(
            HDField<EmptyView>.wraps(at: .accessibility3, axis: .horizontal),
            "a horizontal field is still held to one line at an accessibility content size, which is what clips its text"
        )
        for size in DynamicTypeSize.allCases where size.isAccessibilitySize {
            XCTAssertTrue(
                HDField<EmptyView>.wraps(at: size, axis: .horizontal),
                "a horizontal field is still held to one line at \(size)"
            )
        }
    }

    func testTheComposerIsTallerThanTheSameFieldLaidOutHorizontally() {
        let composer = height(
            placeholder: Self.shortPrompt, axis: .vertical, minimumVisibleLines: 4, at: .large
        )
        let line = height(placeholder: Self.shortPrompt, axis: .horizontal, at: .large)
        XCTAssertGreaterThan(
            composer, line,
            "the composer is \(composer)pt and the same field on one line is \(line)pt, so the axis argument changes nothing"
        )
    }

    func testTheComposerReservesTheLinesItWasAskedFor() {
        let four = height(
            placeholder: Self.shortPrompt, axis: .vertical, minimumVisibleLines: 4, at: .large
        )
        let one = height(
            placeholder: Self.shortPrompt, axis: .vertical, minimumVisibleLines: 1, at: .large
        )
        XCTAssertGreaterThan(
            four - one, Self.twoDefaultLines,
            "a composer asked for four lines is \(four)pt and one asked for a single line is \(one)pt, so minimumVisibleLines reserves nothing"
        )
    }
}
#endif
