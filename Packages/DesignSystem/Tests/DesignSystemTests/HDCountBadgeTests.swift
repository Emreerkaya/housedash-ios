import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

#if canImport(UIKit)
@MainActor
final class HDCountBadgeTests: XCTestCase {
    private func renderedRange(on background: HDToken, colorScheme: ColorScheme) throws -> (low: Double, high: Double) {
        let renderer = ImageRenderer(
            content: HDCountBadge(count: 3, on: background).environment(\.colorScheme, colorScheme)
        )
        renderer.scale = 3
        let image = try XCTUnwrap(renderer.uiImage?.cgImage, "the badge rendered to nothing, so this test measured nothing")
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let space = CGColorSpaceCreateDeviceRGB()
        let context = try XCTUnwrap(
            CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        func linearise(_ channel: Double) -> Double {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        var low = 1.0
        var high = 0.0
        for index in stride(from: 0, to: pixels.count, by: 4) where pixels[index + 3] > 200 {
            let luminance = 0.2126 * linearise(Double(pixels[index]) / 255)
                + 0.7152 * linearise(Double(pixels[index + 1]) / 255)
                + 0.0722 * linearise(Double(pixels[index + 2]) / 255)
            low = min(low, luminance)
            high = max(high, luminance)
        }
        XCTAssertGreaterThan(width * height, 0, "the badge rendered at zero size")
        return (low, high)
    }

    func testTheRenderedBadgeIsLegibleAgainstTheCircleItDrawsInBothSchemes() throws {
        for scheme in [ColorScheme.light, .dark] {
            let range = try renderedRange(on: .onContext, colorScheme: scheme)
            let ratio = (range.high + 0.05) / (range.low + 0.05)
            XCTAssertGreaterThanOrEqual(
                ratio, HDCountBadge.wcagAAForBodyText,
                "the rendered badge spans \(String(format: "%.3f", range.low)) to \(String(format: "%.3f", range.high)) in \(scheme), which is \(String(format: "%.2f", ratio)):1 — the count is a blank dot"
            )
        }
    }

    func testTheInkTheBadgeDerivesIsTheOneTheContrastRuleLeaves() throws {
        let ink = try XCTUnwrap(HDCountBadge.ink(on: .onContext))
        XCTAssertEqual(
            ink, .context,
            "the badge derives \(ink) for its circle, and every other token in the palette fails AA on it in one band or the other"
        )
        XCTAssertNotEqual(
            ink, HDToken.allCases.first,
            "the derivation returns the first token in the palette, so it may not be searching at all"
        )
        XCTAssertLessThan(
            HDContrast.ratio(of: .ink, on: .onContext, in: .dark), HDCountBadge.wcagAAForBodyText,
            "color/ink now clears AA on the circle in dark, which is the pairing the badge shipped with and the reason this derivation exists"
        )
    }
}
#endif
