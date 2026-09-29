import XCTest
import SwiftUI
import UIKit
@testable import DesignSystem

@MainActor
final class HDTabBarSafeAreaTests: XCTestCase {
    private func realWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ??
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    }

    func testThisSimulatorHasARealBottomSafeAreaToDesignAgainst() throws {
        guard let scene = realWindowScene() else {
            throw XCTSkip("No real UIWindowScene is available in this test host.")
        }

        let window = UIWindow(windowScene: scene)
        window.isHidden = false
        window.makeKeyAndVisible()

        XCTAssertGreaterThan(
            window.safeAreaInsets.bottom, 0,
            "F14 only matters when a device actually reports a non-zero bottom safe area; this run confirms one exists to design against"
        )

        window.isHidden = true
    }

    func testTabBarNoLongerBakesTheEightyThreePointHomeIndicatorAllowanceIntoItsOwnSize() {
        let widthProposal = CGSize(width: 393, height: 1000)
        let controller = UIHostingController(rootView: HDTabBarNester(active: .fix) { _ in })
        let naturalHeight = controller.sizeThatFits(in: widthProposal).height

        XCTAssertLessThan(
            naturalHeight, 70,
            """
            the old fixed 83pt (49 of bar plus 34 of home-indicator allowance) is gone; the bar now hugs its \
            own content only and leaves the safe-area allowance to composition (.safeAreaInset at the call \
            site plus .ignoresSafeArea on its own background), so its own natural height should be well under 83
            """
        )
    }
}
