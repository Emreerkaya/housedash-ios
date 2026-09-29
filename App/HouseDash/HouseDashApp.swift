import DesignSystem
import Features
import SwiftUI

@main
struct HouseDashApp: App {
    @State private var authenticatedRole: HDRole?

    var body: some Scene {
        WindowGroup {
            if authenticatedRole != nil {
                HDRootTabView(problemCatalogue: Self.makeProblemCatalogue(), camera: Self.makeCamera())
            } else {
                AuthFlowScreen(identityService: Self.makeIdentityService()) { role in
                    authenticatedRole = role
                }
            }
        }
    }

    private static func makeIdentityService() -> IdentityService {
        #if DEBUG
        FixtureIdentityService()
        #else
        UnavailableIdentityService()
        #endif
    }

    private static func makeProblemCatalogue() -> ProblemCatalogue {
        #if DEBUG
        FixtureProblemCatalogue()
        #else
        UnavailableProblemCatalogue()
        #endif
    }

    private static func makeCamera() -> PhotoCapture {
        #if DEBUG
        FixtureCamera()
        #else
        UnavailableCamera()
        #endif
    }
}
