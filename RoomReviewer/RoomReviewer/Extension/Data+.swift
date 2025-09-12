//
//  Data+.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/12/25.
//

import UIKit

extension Data {
    func downsampledImage() -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1028
        ]
        
        guard let source = CGImageSourceCreateWithData(self as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
