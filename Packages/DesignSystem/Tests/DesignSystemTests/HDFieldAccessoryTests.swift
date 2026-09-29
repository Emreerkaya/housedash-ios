import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

#if canImport(UIKit)
@MainActor
final class HDFieldAccessoryTests: XCTestCase {
    private func measuredSize<V: View>(
        _ view: V,
        proposal: CGSize = CGSize(width: 353, height: 1000),
        dynamicTypeSize: DynamicTypeSize = .large
    ) -> CGSize {
        let controller = UIHostingController(rootView: view.environment(\.dynamicTypeSize, dynamicTypeSize))
        return controller.sizeThatFits(in: proposal)
    }

    func testFieldNoLongerBakesAFixedHeightThatWouldClipAtLargeTypeSizes() {
        let (binding, _) = mutableBinding("")
        let normal = measuredSize(
            HDField(label: "Password", placeholder: "••••••••", text: binding),
            dynamicTypeSize: .large
        )
        let huge = measuredSize(
            HDField(label: "Password", placeholder: "••••••••", text: binding),
            dynamicTypeSize: .accessibility5
        )
        XCTAssertGreaterThan(huge.height, normal.height)
        XCTAssertGreaterThanOrEqual(normal.height, HDField<EmptyView>.minimumHeight)
    }

    func testSecureFieldMasksInputUnlikePlainField() {
        let (binding, _) = mutableBinding("hunter2")
        XCTAssertTrue(
            String(describing: type(of: HDField(label: "Password", placeholder: "", text: binding, isSecure: true).body))
                .contains("SecureField"),
            "isSecure must route through SecureField, not a plain TextField pretending to hide text"
        )
    }

    func testAccessoryViewIsRenderedInsideTheField() {
        let (binding, _) = mutableBinding("")
        let field = HDField(label: "Password", placeholder: "", text: binding) {
            Text("👁")
        }
        XCTAssertTrue(String(describing: type(of: field.body)).contains("Text"))
    }

    private func mutableBinding(_ initial: String) -> (Binding<String>, Box) {
        let box = Box(initial)
        return (Binding(get: { box.value }, set: { box.value = $0 }), box)
    }

    final class Box {
        var value: String
        init(_ value: String) { self.value = value }
    }
}
#endif
