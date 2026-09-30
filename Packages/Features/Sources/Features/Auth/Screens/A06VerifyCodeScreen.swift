import DesignSystem
import SwiftUI

public struct A06VerifyCodeScreen: View {
    @Bindable var model: AuthFlowModel
    @State private var code: String = ""
    @FocusState private var isCodeFieldFocused: Bool

    public init(model: AuthFlowModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            HDHeader(title: "Enter your code", onBack: { model.path.removeLast() })
            HDScreen {
                HDItemStack {
                    HDIdentityRow(identifier: model.identifier) {
                        model.changeIdentifier()
                    }

                    HDText(bannerText, style: HDType.caption, color: bannerColor)

                    HDCodeEntryField(
                        code: $code,
                        isInErrorState: isInErrorState,
                        isFocused: $isCodeFieldFocused
                    )

                    HDPrimaryButton("Verify") {
                        Task { await model.verifyCode(code) }
                    }
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)
                    if let disabledReason {
                        HDText(disabledReason, style: HDType.caption, color: .hdInkFaint)
                    }
                }

                resendRow
            }
        }
        .onAppear { isCodeFieldFocused = true }
        .onChange(of: model.otpBanner) { _, banner in
            switch banner {
            case .wrongCode, .codeExpired, .tooManyAttempts:
                code = ""
            default:
                break
            }
        }
    }

    static func canSubmit(codeCount: Int, banner: OTPBannerState?) -> Bool {
        guard codeCount == HDCodeEntryField.digitCount else { return false }
        switch banner {
        case .codeExpired, .tooManyAttempts:
            return false
        default:
            return true
        }
    }

    static func disabledReason(codeCount: Int, banner: OTPBannerState?) -> String? {
        guard canSubmit(codeCount: codeCount, banner: banner) == false else { return nil }
        switch banner {
        case .codeExpired:
            return "That code expired. Request a new one below."
        case .tooManyAttempts:
            return "Request a new code below to keep going."
        default:
            return codeCount == 0 ? nil : "Enter all 6 digits."
        }
    }

    private var canSubmit: Bool {
        Self.canSubmit(codeCount: code.count, banner: model.otpBanner)
    }

    private var disabledReason: String? {
        Self.disabledReason(codeCount: code.count, banner: model.otpBanner)
    }

    private var isInErrorState: Bool {
        switch model.otpBanner {
        case .wrongCode, .codeExpired, .tooManyAttempts, .offline:
            return true
        default:
            return false
        }
    }

    private var bannerText: String {
        switch model.otpBanner {
        case nil:
            return "Enter the 6-digit code we sent to \(model.identifier)."
        case .codeSent:
            return "We sent a new code to \(model.identifier)."
        case .wrongCode:
            return "That code doesn't match. Try again."
        case .codeExpired:
            return "That code expired. Send a new one to keep going."
        case .tooManyAttempts:
            return "Too many tries. Send a new code to keep going."
        case .rateLimited(let seconds):
            return "Too many requests. Try again in \(Self.formatted(seconds))."
        case .offline:
            return "You're offline. Check your connection and try again."
        }
    }

    private var bannerColor: Color {
        switch model.otpBanner {
        case nil:
            return .hdInkSoft
        case .codeSent:
            return .hdVerified
        default:
            return .hdAlert
        }
    }

    var resendRow: some View {
        HStack {
            Spacer(minLength: 0)
            Button {
                Task { await model.resendCode() }
            } label: {
                HDText(resendTitle, style: HDType.caption, color: model.cooldownRemaining > 0 ? .hdInkFaint : .hdInkSoft)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(model.cooldownRemaining > 0)
            .accessibilityAddTraits(.isButton)
            Spacer(minLength: 0)
        }
    }

    private var resendTitle: String {
        model.cooldownRemaining > 0
            ? "Resend code in \(Self.formatted(model.cooldownRemaining))"
            : "Resend code"
    }

    private static func formatted(_ seconds: Int) -> String {
        guard seconds >= 60 else { return "\(seconds)s" }
        let minutes = seconds / 60
        let remainder = seconds % 60
        return remainder == 0 ? "\(minutes)m" : "\(minutes)m \(remainder)s"
    }
}
