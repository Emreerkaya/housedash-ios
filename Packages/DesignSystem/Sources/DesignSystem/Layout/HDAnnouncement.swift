import SwiftUI

public extension View {
    func hdAnnounce(_ message: String?, onAnnounced: @escaping () -> Void) -> some View {
        onChange(of: message) { _, latest in
            guard let latest, !latest.isEmpty else { return }
            AccessibilityNotification.Announcement(latest).post()
            onAnnounced()
        }
    }
}
