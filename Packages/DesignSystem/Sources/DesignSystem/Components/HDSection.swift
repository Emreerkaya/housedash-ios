import SwiftUI

public struct HDSection: View {
    private let title: String
    private let supportingLine: String

    public init(title: String, supportingLine: String) {
        self.title = title
        self.supportingLine = supportingLine
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HDText(title, style: HDType.bodyStrong, color: .hdInk)
            HDText(supportingLine, style: HDType.caption, color: .hdInkSoft)
        }
    }
}
