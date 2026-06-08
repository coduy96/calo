// Repo convention is swift-testing (import Testing / @Suite / @Test / #expect),
// NOT XCTest -- every existing test (e.g. ImageStoreURLTests) uses it, and a new
// .swift file here is auto-included (PBXFileSystemSynchronizedRootGroup, no pbxproj
// edits). This exercises the PURE function; the UIImage wrapper (cropToFocusSquare)
// is intentionally untested.
import Testing
import Foundation
import CoreGraphics
@testable import calorietracker

@Suite struct FocusCropRectTests {

    // iPhone 15 worked example: w=393, h=852 pts; image 3024x4032 px (4:3 portrait, .up).
    // scale = 852/524 = 1.62595 (>1, applied). side = min(393-64,340) = 329.
    // K = 4032/852 = 4.73239 px/pt. overflow/side = 393*(scale-1)/2 = 123.0 pt.
    // bracket x = 32.0, y = 213.5 pt.
    // crop px: x = (32.0+123.0)*K = 733.52 -> 734; y = 213.5*K = 1010.37 -> 1010;
    //          side = 329*K = 1556.96 -> 1557. Square; in bounds (734+1557=2291<=3024,
    //          1010+1557=2567<=4032).
    @Test func iPhone15WorkedExample() {
        let rect = FocusCrop.focusCropRect(
            imagePixelSize: CGSize(width: 3024, height: 4032),
            screenSize: CGSize(width: 393, height: 852)
        )
        #expect(rect.origin.x == 734)
        #expect(rect.origin.y == 1010)
        #expect(rect.size.width == 1557)
        #expect(rect.size.height == 1557)
    }

    @Test func resultIsAlwaysSquare() {
        let rect = FocusCrop.focusCropRect(
            imagePixelSize: CGSize(width: 3024, height: 4032),
            screenSize: CGSize(width: 393, height: 852)
        )
        #expect(rect.size.width == rect.size.height)
    }

    @Test func staysWithinImageBounds() {
        let rect = FocusCrop.focusCropRect(
            imagePixelSize: CGSize(width: 3024, height: 4032),
            screenSize: CGSize(width: 393, height: 852)
        )
        #expect(rect.minX >= 0)
        #expect(rect.minY >= 0)
        #expect(rect.maxX <= 3024)
        #expect(rect.maxY <= 4032)
    }

    // Degenerate inputs return .null so the wrapper falls back to the original image.
    @Test func degenerateInputsReturnNull() {
        #expect(FocusCrop.focusCropRect(
            imagePixelSize: .zero,
            screenSize: CGSize(width: 393, height: 852)).isNull)
        #expect(FocusCrop.focusCropRect(
            imagePixelSize: CGSize(width: 3024, height: 4032),
            screenSize: .zero).isNull)
    }

    // scale < 1 (genuine fit-to-width that is WIDER than tall -> rawScale < 1,
    // scaleApplied clamped to 1, transform NOT applied) must not crash and must
    // stay in bounds & square. A LANDSCAPE screen forces rawScale < 1:
    // nph = 1024*4/3 = 1365.3 > 768 -> rawScale = 768/1365.3 = 0.5625 < 1.
    // This is the real scaleApplied==1 / previewOriginY<=0 vertical-overflow path,
    // not a letterbox. (Unreachable in the portrait-only shipping camera; tested
    // here only to prove the clamp/guards keep the rect square and in-bounds.)
    @Test func landscapeScaleBelowOneStaysInBoundsAndSquare() {
        let rect = FocusCrop.focusCropRect(
            imagePixelSize: CGSize(width: 1536, height: 2048), // 3:4
            screenSize: CGSize(width: 1024, height: 768)       // landscape -> rawScale < 1
        )
        #expect(!rect.isNull)
        #expect(rect.size.width == rect.size.height)
        #expect(rect.minX >= 0)
        #expect(rect.minY >= 0)
        #expect(rect.maxX <= 1536)
        #expect(rect.maxY <= 2048)
    }
}
