import SwiftUI

public enum HDAnnouncement {
    public static func worthAnnouncing(_ message: String?) -> String? {
        guard let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return message
    }
}

public extension View {
    func hdAnnounce(_ message: String?, onAnnounced: @escaping () -> Void) -> some View {
        onChange(of: message) { _, latest in
            guard let announcement = HDAnnouncement.worthAnnouncing(latest) else { return }
            AccessibilityNotification.Announcement(announcement).post()
            onAnnounced()
        }
    }
}
