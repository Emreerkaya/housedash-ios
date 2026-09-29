import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import DesignSystem
@testable import Features

#if canImport(UIKit)
@MainActor
final class AuthScreensRenderTests: XCTestCase {
    private func measuredSize<V: View>(
        _ view: V,
        proposal: CGSize = CGSize(width: 393, height: CGFloat.infinity),
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> CGSize {
        let controller = UIHostingController(rootView: view.environment(\.dynamicTypeSize, dynamicTypeSize))
        return controller.sizeThatFits(in: proposal)
    }

    private func bodyTypeName<V: View>(_ view: V) -> String {
        String(describing: type(of: view.body))
    }

    private func makeModel(identifier: String = "dana@example.com") -> AuthFlowModel {
        let model = AuthFlowModel(identityService: FakeIdentityService(), onAuthenticated: { _ in })
        model.identifier = identifier
        return model
    }

    // MARK: - The island appears on A02, A02T, A03, A03T only

    func testIslandIsAbsentOnA01() {
        let screen = A01ContinueScreen(model: makeModel())
        XCTAssertFalse(bodyTypeName(screen).contains("HDRoleIsland"))
    }

    func testIslandIsPresentOnWelcomeBack() {
        let screen = A02WelcomeBackScreen(model: makeModel(), knownRoles: [.nester, .tasker])
        XCTAssertTrue(bodyTypeName(screen).contains("HDRoleIsland"))
    }

    func testIslandIsPresentOnCreateAccount() {
        let screen = A03CreateAccountScreen(model: makeModel())
        XCTAssertTrue(bodyTypeName(screen).contains("HDRoleIsland"))
    }

    func testIslandIsAbsentOnAddOtherProfile() {
        let screen = A04AddOtherProfileScreen(model: makeModel(), existingRole: .nester)
        XCTAssertFalse(bodyTypeName(screen).contains("HDRoleIsland"))
    }

    func testIslandIsAbsentOnResetPassword() {
        let screen = A05ResetPasswordScreen(model: makeModel())
        XCTAssertFalse(bodyTypeName(screen).contains("HDRoleIsland"))
    }

    // MARK: - I9: the identifier is typed once and carried forward as an Identity row

    func testIdentifierCarriesForwardOntoWelcomeBack() {
        let screen = A02WelcomeBackScreen(model: makeModel(identifier: "dana@example.com"), knownRoles: [.nester])
        XCTAssertTrue(bodyTypeName(screen).contains("HDIdentityRow"))
    }

    func testIdentifierCarriesForwardOntoCreateAccount() {
        let screen = A03CreateAccountScreen(model: makeModel(identifier: "dana@example.com"))
        XCTAssertTrue(bodyTypeName(screen).contains("HDIdentityRow"))
    }

    func testA01HasNoIdentityRowBecauseNobodyIsIdentifiedYet() {
        let screen = A01ContinueScreen(model: makeModel())
        XCTAssertFalse(bodyTypeName(screen).contains("HDIdentityRow"))
    }

    func testA05DoesNotCarryTheIdentityRowItReEntersTheIdentifier() {
        let screen = A05ResetPasswordScreen(model: makeModel())
        XCTAssertFalse(bodyTypeName(screen).contains("HDIdentityRow"))
    }

    // MARK: - Dynamic Type to the largest accessibility size, nothing clipped

    func testA01GrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(A01ContinueScreen(model: makeModel()), dynamicTypeSize: .large)
        let huge = measuredSize(A01ContinueScreen(model: makeModel()), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(
            huge.height - normal.height, 400,
            "every text-holding block on A01 should grow at accessibility5; a small delta means one of them is clamped"
        )
    }

    func testWelcomeBackGrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(
            A02WelcomeBackScreen(model: makeModel(), knownRoles: [.nester, .tasker]),
            dynamicTypeSize: .large
        )
        let huge = measuredSize(
            A02WelcomeBackScreen(model: makeModel(), knownRoles: [.nester, .tasker]),
            dynamicTypeSize: .accessibility5
        )
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testCreateAccountGrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(A03CreateAccountScreen(model: makeModel()), dynamicTypeSize: .large)
        let huge = measuredSize(A03CreateAccountScreen(model: makeModel()), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testAddOtherProfileGrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(
            A04AddOtherProfileScreen(model: makeModel(), existingRole: .nester),
            dynamicTypeSize: .large
        )
        let huge = measuredSize(
            A04AddOtherProfileScreen(model: makeModel(), existingRole: .nester),
            dynamicTypeSize: .accessibility5
        )
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    func testResetPasswordGrowsInsteadOfClippingAtLargestAccessibilitySize() {
        let normal = measuredSize(A05ResetPasswordScreen(model: makeModel()), dynamicTypeSize: .large)
        let huge = measuredSize(A05ResetPasswordScreen(model: makeModel()), dynamicTypeSize: .accessibility5)
        XCTAssertGreaterThan(huge.height, normal.height)
    }

    // MARK: - 44pt targets on the controls this section adds

    func testForgotPasswordMeetsTheFortyFourPointTouchTarget() {
        let screen = A02WelcomeBackScreen(model: makeModel(), knownRoles: [.nester, .tasker])
        let size = measuredSize(screen.forgotPasswordRow)
        XCTAssertGreaterThanOrEqual(size.height, 44)
    }

    func testNotNowMeetsTheFortyFourPointTouchTarget() {
        let screen = A04AddOtherProfileScreen(model: makeModel(), existingRole: .nester)
        let size = measuredSize(screen.notNowButton)
        XCTAssertGreaterThanOrEqual(size.height, 44)
    }

    func testPasswordRevealButtonMeetsTheFortyFourPointTouchTarget() {
        let size = measuredSize(HDPasswordRevealButton(isRevealed: .constant(false)))
        XCTAssertGreaterThanOrEqual(size.width, 44)
        XCTAssertGreaterThanOrEqual(size.height, 44)
    }
}
#endif
