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
    
    init() {
        memoryCache.totalCostLimit = 150 * 1024 * 1024
    }

    func fetchImage(from urlString: String?) -> Observable<UIImage?> {
        guard let urlString = urlString else {
            return .just(nil)
        }
        
        let cacheKey = NSString(string: urlString)
        
        // 메모리 캐시에서 이미지 체크
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return .just(cachedImage)
        }
        
        // 캐시가 없으면 네트워크 다운로드
        return loadImage(urlString)
            .asObservable()
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .flatMap { [weak self] result -> Observable<UIImage?> in
                guard let self = self else { return .just(nil) }
                
                switch result {
                case .success(let data):
                    // 다운샘플링 진행
                    let downsampledImage = downsampledImage(data: data)
                    
                    // 캐시에 저장
                    if let image = downsampledImage {
                        self.memoryCache.setObject(image, forKey: cacheKey)
                    }
                    
                    return .just(downsampledImage)
                    
                case .failure:
                    return .just(nil)
                }
            }
    }
    
    private func loadImage(_ urlString: String?) -> Single<Result<Data, Error>> {
        return Single.create { single in
            guard let urlString = urlString, let url = URL(string: API.tmdbImageURL + urlString) else {
                single(.success(.failure(NetworkError.invalidURL)))
                return Disposables.create()
            }
            
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    return single(.success(.failure(error)))
                }
                
                guard let response = response as? HTTPURLResponse,
                      response.statusCode == 200 else {
                    return single(.success(.failure(NetworkError.invalidResponse)))
                }
                
                guard let data = data else {
                    return single(.success(.failure(NetworkError.invalidData)))
                }
                
                return single(.success(.success(data)))
            }
            
            task.resume()
            
            return Disposables.create() {
                task.cancel()
            }
        }
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
