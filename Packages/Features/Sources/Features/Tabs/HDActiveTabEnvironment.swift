import SwiftUI
import DesignSystem

private struct HDActiveTabKey: EnvironmentKey {
    static let defaultValue: HDNesterTab? = nil
}

public extension EnvironmentValues {
    var hdActiveTab: HDNesterTab? {
        get { self[HDActiveTabKey.self] }
        set { self[HDActiveTabKey.self] = newValue }
    }
}
