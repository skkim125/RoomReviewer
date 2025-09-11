//
//  ImageProvider.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/15/25.
//

import UIKit
import RxSwift

protocol ImageProviding {
    func fetchImage(from urlString: String?) -> Observable<UIImage?>
}

final class ImageProvider: ImageProviding {
    // 메모리 캐시
    // [url: UIImage]
    private let memoryCache = NSCache<NSString, UIImage>()
    private let dataFetcher: DataFetching
    
    init(dataFetcher: DataFetching) {
        self.dataFetcher = dataFetcher
        memoryCache.totalCostLimit = 150 * 1024 * 1024
    }

    func fetchImage(from urlString: String?) -> Observable<UIImage?> {
        guard let urlString = urlString, let url = URL(string: API.tmdbImageURL + urlString) else {
            return .just(nil)
        }
        
        let cacheKey = NSString(string: url.absoluteString)
        
        // 메모리 캐시에서 이미지 체크
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return .just(cachedImage)
        }
        
        let request = URLRequest(url: url)
        // 캐시가 없으면 네트워크 다운로드
        return dataFetcher.fetchData(request: request)
            .asObservable()
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map { [weak self] data -> UIImage? in
                guard let self = self else { return nil }
                
                // 다운샘플링 진행
                let downsampledImage = self.downsampledImage(data: data)
                
                // 캐시에 저장
                if let image = downsampledImage {
                    self.memoryCache.setObject(image, forKey: cacheKey)
                }
                
                return downsampledImage
            }
            .catchAndReturn(nil) // 에러 발생 시 nil 반환
    }
    
    private func downsampledImage(data: Data) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1028
        ]

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
