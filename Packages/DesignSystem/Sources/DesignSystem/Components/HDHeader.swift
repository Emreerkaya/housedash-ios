import SwiftUI

public struct HDHeader: View {
    public struct Action {
        public let title: String
        public let handler: () -> Void

        public init(title: String, handler: @escaping () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    private let title: String
    private let onBack: (() -> Void)?
    private let action: Action?

    public init(title: String, onBack: (() -> Void)? = nil, action: Action? = nil) {
        self.title = title
        self.onBack = onBack
        self.action = action
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if onBack != nil || action != nil {
                HStack(alignment: .center, spacing: 0) {
                    if let onBack {
                        Button(action: onBack) {
                            HDText("‹", style: HDType.chevron, color: .hdInk)
                                .frame(width: 44, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 0)

                    if let action {
                        Button(action: action.handler) {
                            HDText(action.title, style: HDType.label, color: .hdInkSoft)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .clipped()
            }

            HDText(title, style: HDType.titleLarge, color: .hdInk)
        }
        .padding(.horizontal, HDSpacing.margin)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .clipped()
    }
}
