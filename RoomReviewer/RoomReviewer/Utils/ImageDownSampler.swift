//
//  ImageDownSampler.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/14/25.
//

import UIKit
import ImageIO

final class ImageDownSampler {
    static let shared = ImageDownSampler()
    private init() { }
    
    func downsampledImage(data: Data, size: CGSize) -> UIImage? {
        let maxDimensionInPixels = max(size.width, size.height) * UIScreen.main.scale
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ]

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
