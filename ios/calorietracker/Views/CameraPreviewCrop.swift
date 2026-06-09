import UIKit

/// Crops a captured camera photo to the region that was actually visible in the
/// live camera preview.
///
/// `CameraView` aspect-fills the device's 4:3 sensor feed into the full screen
/// (via `cameraViewTransform`), so while framing the user only sees the centre
/// slice of the sensor — on a portrait iPhone the full height is shown but the
/// left/right edges are off-screen. The saved photo (`info[.originalImage]`),
/// however, is the *entire* 4:3 frame. Displaying that full frame afterwards
/// makes the subject look smaller and off-centre versus what was framed.
///
/// Cropping the photo to the screen's aspect ratio reproduces exactly what was
/// on-screen at capture time: "what you framed is what you get."
enum CameraPreviewCrop {

    /// The centred crop rectangle, in pixels, that aspect-fills an image of
    /// `imagePixelSize` into a screen whose aspect ratio (width / height) is
    /// `screenAspect`. Pure geometry, no UIKit state, so it is unit-testable.
    ///
    /// Keeps the full extent of the dimension that fills the screen and trims
    /// the dimension that overflows, centred. For a portrait iPhone
    /// (`screenAspect` ≈ 0.46) against a portrait 4:3 photo this keeps the full
    /// height and trims the left/right margins. Returns the full rect for
    /// degenerate input.
    static func cropRect(imagePixelSize size: CGSize, screenAspect: CGFloat) -> CGRect {
        let w = size.width
        let h = size.height
        guard w > 0, h > 0, screenAspect > 0, screenAspect.isFinite else {
            return CGRect(origin: .zero, size: size)
        }

        let imageAspect = w / h
        let cropW: CGFloat
        let cropH: CGFloat
        if imageAspect > screenAspect {
            // Image is wider than the screen → trim width, keep full height.
            cropW = min((h * screenAspect).rounded(), w)
            cropH = h
        } else {
            // Image is taller/narrower than the screen → trim height, keep full width.
            cropW = w
            cropH = min((w / screenAspect).rounded(), h)
        }

        let originX = ((w - cropW) / 2).rounded(.down)
        let originY = ((h - cropH) / 2).rounded(.down)
        return CGRect(x: originX, y: originY, width: cropW, height: cropH)
    }

    /// Returns `image` cropped to the camera-preview viewport for a screen of
    /// aspect `screenAspect`. Orientation is normalised first so the crop is
    /// applied in display space. Returns the original image unchanged when it
    /// has no backing `CGImage`, when geometry is degenerate, or when no crop
    /// is needed.
    static func cropToPreview(_ image: UIImage, screenAspect: CGFloat) -> UIImage {
        guard screenAspect > 0, screenAspect.isFinite else { return image }

        let upright = normalizedUp(image)
        guard let cg = upright.cgImage, cg.width > 0, cg.height > 0 else { return image }

        let pixelSize = CGSize(width: cg.width, height: cg.height)
        let rect = cropRect(imagePixelSize: pixelSize, screenAspect: screenAspect)

        // Nothing to trim — avoid a pointless re-encode.
        if rect.origin == .zero, rect.size == pixelSize { return upright }

        guard let cropped = cg.cropping(to: rect) else { return upright }
        return UIImage(cgImage: cropped, scale: upright.scale, orientation: .up)
    }

    /// Returns `image` with its pixel buffer baked to `.up` orientation (no
    /// crop). Use when keeping the full camera frame but guaranteeing the saved
    /// photo is upright for display, storage, and AI upload.
    static func uprightImage(_ image: UIImage) -> UIImage {
        normalizedUp(image)
    }

    /// Crops the captured full-frame photo to the camera's focus-frame square
    /// (the on-screen bracket region), mapped through the `resizeAspect` preview
    /// into image space. Returns an upright square crop for the circular loading
    /// thumbnail — the full saved photo is left untouched. Falls back to a
    /// centred square (or the whole image) for degenerate input.
    static func focusSquareImage(_ image: UIImage, screenSize: CGSize) -> UIImage {
        let upright = normalizedUp(image)
        guard let cg = upright.cgImage, cg.width > 0, cg.height > 0,
              screenSize.width > 0, screenSize.height > 0 else { return upright }

        let imgW = CGFloat(cg.width)
        let imgH = CGFloat(cg.height)
        let imageAspect = imgW / imgH
        let screenAspect = screenSize.width / screenSize.height

        // The preview rect: the photo aspect-FIT (resizeAspect) into the screen.
        let previewRect: CGRect
        if imageAspect > screenAspect {
            let h = screenSize.width / imageAspect
            previewRect = CGRect(x: 0, y: (screenSize.height - h) / 2, width: screenSize.width, height: h)
        } else {
            let w = screenSize.height * imageAspect
            previewRect = CGRect(x: (screenSize.width - w) / 2, y: 0, width: w, height: screenSize.height)
        }
        guard previewRect.width > 0, previewRect.height > 0 else { return upright }

        // Map the focus-frame square (screen coords) into image pixels.
        let bracket = CameraOverlayView.focusFrameRect(in: screenSize)
        let px = (bracket.minX - previewRect.minX) / previewRect.width * imgW
        let py = (bracket.minY - previewRect.minY) / previewRect.height * imgH
        let pw = bracket.width / previewRect.width * imgW
        let ph = bracket.height / previewRect.height * imgH

        let rect = CGRect(x: px, y: py, width: pw, height: ph)
            .integral
            .intersection(CGRect(x: 0, y: 0, width: imgW, height: imgH))
        guard rect.width > 0, rect.height > 0, let cropped = cg.cropping(to: rect) else { return upright }
        return UIImage(cgImage: cropped, scale: upright.scale, orientation: .up)
    }

    /// Redraws `image` so its pixel buffer is upright (`.up` orientation),
    /// letting the crop be expressed directly in display coordinates.
    private static func normalizedUp(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
