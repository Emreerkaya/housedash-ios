import SwiftUI

public struct HDCodeEntryField: View {
    public static let digitCount = 6
    public static let boxSize: CGFloat = 48
    public static let boxSpacing: CGFloat = 10
    public static let cornerRadius: CGFloat = 14

    public static func sanitize(_ input: String) -> String {
        String(input.filter(\.isNumber).prefix(digitCount))
    }

    @Binding var code: String
    let isInErrorState: Bool
    @FocusState.Binding var isFocused: Bool

    public init(code: Binding<String>, isInErrorState: Bool, isFocused: FocusState<Bool>.Binding) {
        self._code = code
        self.isInErrorState = isInErrorState
        self._isFocused = isFocused
    }

    private var digitCharacters: [Character?] {
        var characters = Array(code).map { Optional($0) }
        while characters.count < Self.digitCount { characters.append(nil) }
        return characters
    }

    public var body: some View {
        ZStack {
            HStack(spacing: Self.boxSpacing) {
                ForEach(0..<Self.digitCount, id: \.self) { index in
                    box(for: digitCharacters[index], isCurrent: index == code.count)
                }
            }

            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .foregroundStyle(Color.clear)
                .tint(Color.clear)
                .accessibilityIdentifier("Verification code")
                .accessibilityLabel("Verification code")
                .accessibilityValue(code)
                .onChange(of: code) { _, newValue in
                    let sanitized = Self.sanitize(newValue)
                    if sanitized != newValue { code = sanitized }
                }
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }

    private func box(for character: Character?, isCurrent: Bool) -> some View {
        HDText(character.map(String.init) ?? "", style: HDType.titleLarge, color: .hdInk)
            .frame(width: Self.boxSize, height: Self.boxSize)
            .background(
                Color.hdSurfaceSunk,
                in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .stroke(borderColor(isCurrent: isCurrent), lineWidth: isCurrent || isInErrorState ? 2 : 1)
            )
    }

    private func borderColor(isCurrent: Bool) -> Color {
        if isInErrorState { return .hdAlert }
        if isCurrent && isFocused { return .hdContext }
        return .hdHairline
    }
}
