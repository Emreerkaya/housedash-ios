import SwiftUI

private struct HDActiveTabKey: EnvironmentKey {
    static let defaultValue: HDTab? = nil
}

public extension EnvironmentValues {
    var hdActiveTab: HDTab? {
        get { self[HDActiveTabKey.self] }
        set { self[HDActiveTabKey.self] = newValue }
    }
}
