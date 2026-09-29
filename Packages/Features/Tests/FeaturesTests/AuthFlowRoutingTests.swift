import XCTest
@testable import Features

@MainActor
final class AuthFlowRoutingTests: XCTestCase {
    private func makeModel(
        onAuthenticated: @escaping (HDRole) -> Void = { _ in }
    ) -> (AuthFlowModel, FakeIdentityService) {
        let service = FakeIdentityService()
        let model = AuthFlowModel(identityService: service, onAuthenticated: onAuthenticated)
        return (model, service)
    }

    func testKnownIdentifierRoutesToSignIn() async {
        let (model, _) = makeModel()
        model.identifier = "dana@example.com"

        await model.submitIdentifier()

        XCTAssertEqual(model.path, [.signIn(knownRoles: [.nester, .tasker])])
    }

    func testNewIdentifierRoutesToCreateAccount() async {
        let (model, _) = makeModel()
        model.identifier = "brandnew@example.com"

        await model.submitIdentifier()

        XCTAssertEqual(model.path, [.createAccount])
    }

    func testIdentifierSurvivesAcrossEveryRouteChange() async {
        let (model, _) = makeModel()
        model.identifier = "dana@example.com"

        await model.submitIdentifier()
        XCTAssertEqual(model.identifier, "dana@example.com")

        model.goToResetPassword()
        XCTAssertEqual(model.identifier, "dana@example.com")

        model.changeIdentifier()
        XCTAssertEqual(model.identifier, "dana@example.com", "Change must return to A01 without erasing what was typed")
        XCTAssertEqual(model.path, [])
    }

    func testSSOAlwaysRoutesToCreateAccountBecauseARoleStillHasToBeChosen() {
        let (model, _) = makeModel()
        model.identifier = "dana@example.com"

        model.continueWithSSO()

        XCTAssertEqual(model.path, [.createAccount])
    }

    func testSignInToASingleRoleAccountOffersTheOtherProfileBeforeAuthenticating() async {
        var authenticatedRoles: [HDRole] = []
        let (model, _) = makeModel(onAuthenticated: { authenticatedRoles.append($0) })
        model.identifier = "solo@example.com"
        await model.submitIdentifier()

        await model.signIn(password: "correct-horse")

        XCTAssertTrue(authenticatedRoles.isEmpty, "a single-profile account must see A04 before landing in the app")
        XCTAssertEqual(model.path.last, .addOtherProfile(existingRole: .nester))
    }

    func testSignInToADualRoleAccountAuthenticatesDirectlyWithNoA04Offer() async {
        var authenticatedRoles: [HDRole] = []
        let (model, _) = makeModel(onAuthenticated: { authenticatedRoles.append($0) })
        model.identifier = "dana@example.com"
        await model.submitIdentifier()

        await model.signIn(password: "correct-horse")

        XCTAssertEqual(authenticatedRoles, [.nester])
    }

    func testCreateAccountAuthenticatesDirectlyWithNoA04Offer() async {
        var authenticatedRoles: [HDRole] = []
        let (model, _) = makeModel(onAuthenticated: { authenticatedRoles.append($0) })
        model.identifier = "brandnew@example.com"
        await model.submitIdentifier()
        model.selectedRole = .tasker

        await model.createAccount(password: "correct-horse")

        XCTAssertEqual(authenticatedRoles, [.tasker])
    }

    func testWrongPasswordSurfacesAnErrorRatherThanAuthenticating() async {
        var authenticatedRoles: [HDRole] = []
        let (model, service) = makeModel(onAuthenticated: { authenticatedRoles.append($0) })
        model.identifier = "unknown@example.com"
        service.accounts["unknown@example.com"] = nil

        await model.signIn(password: "whatever")

        XCTAssertTrue(authenticatedRoles.isEmpty)
        XCTAssertNotNil(model.errorMessage)
    }

    func testResetPasswordLinkSentReturnsToA01() {
        let (model, _) = makeModel()
        model.identifier = "dana@example.com"
        model.goToResetPassword()
        XCTAssertEqual(model.path, [.resetPassword])

        model.requestPasswordReset()

        XCTAssertEqual(model.path, [])
    }

    func testNotNowOnAddOtherProfileAuthenticatesWithTheExistingRoleOnly() {
        var authenticatedRoles: [HDRole] = []
        let (model, _) = makeModel(onAuthenticated: { authenticatedRoles.append($0) })

        model.dismissAddOtherProfile(currentRole: .nester)

        XCTAssertEqual(authenticatedRoles, [.nester])
    }
}
