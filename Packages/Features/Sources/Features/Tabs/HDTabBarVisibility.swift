import SwiftUI

private struct HDTabBarHiddenPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

public extension View {
    func hdTabBarHidden(_ hidden: Bool = true) -> some View {
        preference(key: HDTabBarHiddenPreferenceKey.self, value: hidden)
    }

    func onHDTabBarHiddenChange(_ action: @escaping (Bool) -> Void) -> some View {
        onPreferenceChange(HDTabBarHiddenPreferenceKey.self, perform: action)
    }
}
