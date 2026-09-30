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

    func testSubmitIdentifierRequestsACodeAndRoutesToVerifyCode() async {
        let (model, service) = makeModel()
        model.identifier = "dana@example.com"

        await model.submitIdentifier()

        XCTAssertEqual(service.requestCodeCallCount, 1)
        XCTAssertEqual(model.path, [.verifyCode])
        XCTAssertEqual(model.otpBanner, .codeSent)
        XCTAssertEqual(model.cooldownRemaining, service.requestCodeCooldown)
    }

    func testSubmitIdentifierDoesNothingForAnEmptyIdentifier() async {
        let (model, service) = makeModel()
        model.identifier = "   "

        await model.submitIdentifier()

        XCTAssertEqual(service.requestCodeCallCount, 0)
        XCTAssertEqual(model.path, [])
    }

    func testSubmitIdentifierSurfacesAnInlineMessageWhenIssuanceIsRateLimited() async {
        let (model, service) = makeModel()
        model.identifier = "dana@example.com"
        service.nextRequestCodeError = .rateLimited(retryAfterSeconds: 20)

        await model.submitIdentifier()

        XCTAssertEqual(model.path, [])
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.errorMessage!.lowercased().contains("account"))
    }

    func testIdentifierSurvivesAcrossEveryRouteChange() async {
        let (model, _) = makeModel()
        model.identifier = "dana@example.com"

        await model.submitIdentifier()
        XCTAssertEqual(model.identifier, "dana@example.com")

        await model.verifyCode(FakeIdentityService.validCode)
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

    func testVerifyCodeForAnExistingSingleRoleAccountRoutesToSignIn() async {
        let (model, _) = makeModel()
        model.identifier = "solo@example.com"
        await model.submitIdentifier()

        await model.verifyCode(FakeIdentityService.validCode)

        XCTAssertEqual(model.path, [.signIn(knownRoles: [.nester])])
        XCTAssertEqual(model.selectedRole, .nester)
        XCTAssertNil(model.otpBanner)
    }

    func testVerifyCodeForAnExistingDualRoleAccountRoutesToSignIn() async {
        let (model, _) = makeModel()
        model.identifier = "dana@example.com"
        await model.submitIdentifier()

        await model.verifyCode(FakeIdentityService.validCode)

        XCTAssertEqual(model.path, [.signIn(knownRoles: [.nester, .tasker])])
    }

    func testVerifyCodeForANewIdentifierRoutesToCreateAccount() async {
        let (model, _) = makeModel()
        model.identifier = "brandnew@example.com"
        await model.submitIdentifier()

        await model.verifyCode(FakeIdentityService.validCode)

        XCTAssertEqual(model.path, [.createAccount])
        XCTAssertEqual(model.selectedRole, .nester)
    }

    func testWrongCodeSurfacesTheWrongCodeBannerRatherThanNavigating() async {
        let (model, _) = makeModel()
        model.identifier = "dana@example.com"
        await model.submitIdentifier()

        await model.verifyCode("000000")

        XCTAssertEqual(model.path, [.verifyCode])
        XCTAssertEqual(model.otpBanner, .wrongCode)
    }

    func testCodeExpiredSurfacesTheExpiredBannerRatherThanNavigating() async {
        let (model, service) = makeModel()
        model.identifier = "dana@example.com"
        await model.submitIdentifier()
        service.nextVerifyCodeError = .codeExpired

        await model.verifyCode(FakeIdentityService.validCode)

        XCTAssertEqual(model.path, [.verifyCode])
        XCTAssertEqual(model.otpBanner, .codeExpired)
    }

    func testTooManyAttemptsSurfacesItsOwnBannerRatherThanTheGenericWrongCodeOne() async {
        let (model, service) = makeModel()
        model.identifier = "dana@example.com"
        await model.submitIdentifier()
        service.nextVerifyCodeError = .tooManyAttempts

        await model.verifyCode(FakeIdentityService.validCode)

        XCTAssertEqual(model.otpBanner, .tooManyAttempts)
    }

    func testOfflineDuringVerifySurfacesTheOfflineBanner() async {
        let (model, service) = makeModel()
        model.identifier = "dana@example.com"
        await model.submitIdentifier()
        service.nextVerifyCodeError = .offline

        await model.verifyCode(FakeIdentityService.validCode)

        XCTAssertEqual(model.otpBanner, .offline)
    }

    func testResendIsRefusedWhileTheCooldownIsRunning() async {
        let (model, service) = makeModel()
        model.identifier = "dana@example.com"
        await model.submitIdentifier()
        XCTAssertGreaterThan(model.cooldownRemaining, 0)

        await model.resendCode()

        XCTAssertEqual(service.requestCodeCallCount, 1, "resend must not fire a second request while the cooldown is still running")
    }

    func testResendRequestsANewCodeOnceTheCooldownHasElapsed() async {
        let (model, service) = makeModel()
        model.identifier = "dana@example.com"
        await model.submitIdentifier()
        model.cooldownRemaining = 0

        await model.resendCode()

        XCTAssertEqual(service.requestCodeCallCount, 2)
        XCTAssertEqual(model.otpBanner, .codeSent)
    }

    func testRateLimitedResendSetsTheBannerAndBeginsACooldownFromTheServersValue() async {
        let (model, service) = makeModel()
        model.identifier = "dana@example.com"
        await model.submitIdentifier()
        model.cooldownRemaining = 0
        service.nextRequestCodeError = .rateLimited(retryAfterSeconds: 90)

        await model.resendCode()

        XCTAssertEqual(model.otpBanner, .rateLimited(retryAfterSeconds: 90))
        XCTAssertEqual(model.cooldownRemaining, 90)
    }

    func testChangeIdentifierClearsTheOTPBannerAndCooldown() async {
        let (model, _) = makeModel()
        model.identifier = "dana@example.com"
        await model.submitIdentifier()

        model.changeIdentifier()

        XCTAssertNil(model.otpBanner)
        XCTAssertEqual(model.cooldownRemaining, 0)
    }

    func testCompleteSignInToASingleRoleAccountOffersTheOtherProfileBeforeAuthenticating() async {
        var authenticatedRoles: [HDRole] = []
        let (model, _) = makeModel(onAuthenticated: { authenticatedRoles.append($0) })
        model.identifier = "solo@example.com"
        await model.submitIdentifier()
        await model.verifyCode(FakeIdentityService.validCode)

        model.completeSignIn()

        XCTAssertTrue(authenticatedRoles.isEmpty, "a single-profile account must see A04 before landing in the app")
        XCTAssertEqual(model.path.last, .addOtherProfile(existingRole: .nester))
    }

    func testCompleteSignInToADualRoleAccountAuthenticatesDirectlyWithNoA04Offer() async {
        var authenticatedRoles: [HDRole] = []
        let (model, _) = makeModel(onAuthenticated: { authenticatedRoles.append($0) })
        model.identifier = "dana@example.com"
        await model.submitIdentifier()
        await model.verifyCode(FakeIdentityService.validCode)

        model.completeSignIn()

        XCTAssertEqual(authenticatedRoles, [.nester])
    }

    func testCreateAccountAuthenticatesDirectlyWithNoA04Offer() async {
        var authenticatedRoles: [HDRole] = []
        let (model, _) = makeModel(onAuthenticated: { authenticatedRoles.append($0) })
        model.identifier = "brandnew@example.com"
        await model.submitIdentifier()
        await model.verifyCode(FakeIdentityService.validCode)
        model.selectedRole = .tasker

        await model.createAccount()

        XCTAssertEqual(authenticatedRoles, [.tasker])
    }

    func testNotNowOnAddOtherProfileAuthenticatesWithTheExistingRoleOnly() {
        var authenticatedRoles: [HDRole] = []
        let (model, _) = makeModel(onAuthenticated: { authenticatedRoles.append($0) })

        model.dismissAddOtherProfile(currentRole: .nester)

        XCTAssertEqual(authenticatedRoles, [.nester])
    }
}
