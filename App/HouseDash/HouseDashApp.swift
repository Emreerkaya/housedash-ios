import DesignSystem
import Features
import SwiftUI

@main
struct HouseDashApp: App {
    @State private var authenticatedRole: HDRole?

    var body: some Scene {
        WindowGroup {
            if authenticatedRole != nil {
                HDRootTabView()
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
}
