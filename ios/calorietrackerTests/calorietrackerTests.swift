//
//  calorietrackerTests.swift
//  calorietrackerTests
//
//  Created by Apoorv Darshan on 05/02/26.
//

import Testing
import UIKit
@testable import calorietracker

struct calorietrackerTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

// MARK: - Image downscaling (fixes food-analysis Supabase timeout)

struct ImageDownscaleTests {

    /// Build a scale-1 image so `size` equals pixel dimensions and assertions
    /// are deterministic regardless of the host device's screen scale.
    private func makeImage(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        )
        return renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    private func pixelLongestEdge(_ image: UIImage) -> CGFloat {
        max(image.size.width * image.scale, image.size.height * image.scale)
    }

    @Test func capsLongestEdgeOfLargePhoto() {
        let large = makeImage(width: 4032, height: 3024) // 12 MP
        let result = large.downscaled(maxDimension: 1536)
        #expect(pixelLongestEdge(result) <= 1536)
    }

    @Test func preservesAspectRatio() {
        let large = makeImage(width: 4032, height: 3024)
        let result = large.downscaled(maxDimension: 1536)
        let inputRatio = 4032.0 / 3024.0
        let outputRatio = (result.size.width * result.scale) / (result.size.height * result.scale)
        #expect(abs(outputRatio - inputRatio) < 0.02)
    }

    @Test func leavesSmallImageWithinBounds() {
        let small = makeImage(width: 800, height: 600)
        let result = small.downscaled(maxDimension: 1536)
        #expect(pixelLongestEdge(result) <= 1536)
    }

    /// The actual bug: a full-res photo must encode to a payload small enough
    /// to upload within the request timeout. Verify the downscaled JPEG is a
    /// fraction of the full-resolution encoding.
    @Test func shrinksEncodedPayloadOfLargePhoto() throws {
        let large = makeImage(width: 4032, height: 3024)
        let fullSize = try #require(large.jpegData(compressionQuality: 0.8)).count
        let downscaled = try #require(large.downscaled(maxDimension: 1536).jpegData(compressionQuality: 0.8)).count
        #expect(downscaled < fullSize / 4)
    }
}
