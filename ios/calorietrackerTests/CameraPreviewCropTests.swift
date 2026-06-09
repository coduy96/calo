import Testing
import UIKit
@testable import calorietracker

struct CameraPreviewCropTests {

    // MARK: - Pure geometry

    /// Portrait iPhone framing a portrait 4:3 photo: the full height must be
    /// kept and the left/right margins trimmed symmetrically — this is the
    /// exact mismatch the user reported ("zoomed out / wrong position").
    @Test func portraitPhoneTrimsWidthKeepsFullHeight() {
        let screenAspect: CGFloat = 393.0 / 852.0
        let rect = CameraPreviewCrop.cropRect(
            imagePixelSize: CGSize(width: 3024, height: 4032),
            screenAspect: screenAspect
        )
        #expect(rect.height == 4032)            // full height retained
        #expect(rect.origin.y == 0)
        #expect(rect.origin.x > 0)              // trimmed from the sides
        #expect(abs(rect.origin.x - (3024 - rect.width) / 2) <= 1)   // centred
        #expect(abs(rect.width / rect.height - screenAspect) < 0.001) // matches screen
    }

    /// Image taller/narrower than the target aspect → trim height, keep width.
    @Test func tallImageTrimsHeightKeepsFullWidth() {
        let rect = CameraPreviewCrop.cropRect(
            imagePixelSize: CGSize(width: 100, height: 1000),
            screenAspect: 0.5
        )
        #expect(rect.width == 100)
        #expect(rect.origin.x == 0)
        #expect(rect.origin.y > 0)
        #expect(abs(rect.width / rect.height - 0.5) < 0.01)
    }

    /// Image already at the screen aspect → no crop (full rect).
    @Test func matchingAspectIsNoOp() {
        let size = CGSize(width: 461, height: 1000)
        let rect = CameraPreviewCrop.cropRect(imagePixelSize: size, screenAspect: 0.461)
        #expect(rect.origin == .zero)
        #expect(rect.width == 461)
        #expect(abs(rect.height - 1000) <= 1)
    }

    /// The crop never escapes the image bounds, for a spread of real sizes.
    @Test func cropStaysWithinBounds() {
        let sizes = [CGSize(width: 3024, height: 4032),
                     CGSize(width: 4032, height: 3024),
                     CGSize(width: 1080, height: 1920),
                     CGSize(width: 1000, height: 1000)]
        for size in sizes {
            let rect = CameraPreviewCrop.cropRect(imagePixelSize: size, screenAspect: 393.0 / 852.0)
            #expect(rect.minX >= 0)
            #expect(rect.minY >= 0)
            #expect(rect.maxX <= size.width)
            #expect(rect.maxY <= size.height)
            #expect(rect.width > 0)
            #expect(rect.height > 0)
        }
    }

    /// Degenerate inputs fall back to the full rect rather than crashing.
    @Test func degenerateInputsReturnFullRect() {
        let size = CGSize(width: 300, height: 400)
        #expect(CameraPreviewCrop.cropRect(imagePixelSize: size, screenAspect: 0)
                == CGRect(origin: .zero, size: size))
        #expect(CameraPreviewCrop.cropRect(imagePixelSize: .zero, screenAspect: 0.5)
                == CGRect(origin: .zero, size: .zero))
    }

    // MARK: - End-to-end on a real UIImage

    /// An upright 300×400 image cropped to aspect 0.5 → 200×400 (trim width).
    @Test func cropsUprightImageToScreenAspect() {
        let base = solidImage(width: 300, height: 400)
        let out = CameraPreviewCrop.cropToPreview(base, screenAspect: 0.5)
        #expect(Int(out.size.width.rounded()) == 200)
        #expect(Int(out.size.height.rounded()) == 400)
    }

    /// Orientation must be baked in before cropping: a `.right` image reports a
    /// swapped display size, and the crop must be applied to the upright pixels.
    @Test func bakesOrientationBeforeCropping() {
        let base = solidImage(width: 300, height: 400)
        let rotated = UIImage(cgImage: base.cgImage!, scale: base.scale, orientation: .right)
        #expect(Int(rotated.size.width.rounded()) == 400)   // sanity: display size swapped

        let out = CameraPreviewCrop.cropToPreview(rotated, screenAspect: 0.5)
        // Upright is 400×300 (aspect 1.333 > 0.5) → trim width: 300*0.5 = 150 wide.
        #expect(Int(out.size.width.rounded()) == 150)
        #expect(Int(out.size.height.rounded()) == 300)
        #expect(out.imageOrientation == .up)
    }

    // MARK: - Focus-frame square crop (loading thumbnail)

    /// The focus-frame crop is a square (the bracket is square and resizeAspect
    /// preserves aspect uniformly), centred horizontally, strictly inside the
    /// photo — i.e. it actually crops to the framed region.
    @Test func focusSquareIsSquareAndInsidePhoto() {
        let base = solidImage(width: 300, height: 400) // 3:4 like a real photo
        let out = CameraPreviewCrop.focusSquareImage(base, screenSize: CGSize(width: 390, height: 844))
        let w = out.size.width * out.scale
        let h = out.size.height * out.scale
        #expect(abs(w - h) <= 2)        // square
        #expect(w < 300)                // actually cropped (not the whole frame)
        #expect(h < 400)
        #expect(w > 100)                // and a meaningful region, not degenerate
        #expect(out.imageOrientation == .up)
    }

    /// Degenerate screen size falls back to the (upright) full image, no crash.
    @Test func focusSquareDegenerateFallsBack() {
        let base = solidImage(width: 300, height: 400)
        let out = CameraPreviewCrop.focusSquareImage(base, screenSize: .zero)
        #expect(Int(out.size.width.rounded()) == 300)
        #expect(Int(out.size.height.rounded()) == 400)
    }

    // MARK: - Helpers

    private func solidImage(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.image { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
}
