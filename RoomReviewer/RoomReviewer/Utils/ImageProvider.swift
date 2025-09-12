//
//  ImageProvider.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/15/25.
//

import UIKit
import RxSwift

protocol ImageProviding {
    func fetchImage(urlString: String?) -> Observable<UIImage?>
}

final class ImageProvider: ImageProviding {
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacher: DiskImageCacher
    private let dataFetcher: DataFetching
    
    init(diskCacher: DiskImageCacher, dataFetcher: DataFetching) {
        self.diskCacher = diskCacher
        self.dataFetcher = dataFetcher
        memoryCache.totalCostLimit = 150 * 1024 * 1024
    }
    
    func fetchImage(urlString: String?) -> Observable<UIImage?> {
        guard let urlString = urlString, let url = URL(string: API.tmdbImageURL + urlString) else {
            return .just(nil)
        }
        
        let cacheKey = NSString(string: url.absoluteString)
        
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return .just(cachedImage)
        }
        
        if let localImageData = diskCacher.load(key: url.absoluteString), let localImage = UIImage(data: localImageData) {
            memoryCache.setObject(localImage, forKey: cacheKey)
            return .just(localImage)
        }
        
        let request = URLRequest(url: url)
        return dataFetcher.fetchData(request: request)
            .asObservable()
            .flatMap { [weak self] data -> Observable<UIImage?> in
                guard let self = self else { return .empty() }
                
                self.diskCacher.save(data: data, key: url.absoluteString)
                
                return Observable.just(data)
                    .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
                    .map { data -> UIImage? in
                        guard let image = data.downsampledImage() else { return nil }
                        self.memoryCache.setObject(image, forKey: cacheKey)
                        return image
                    }
            }
            .observe(on: MainScheduler.instance)
            .catchAndReturn(nil)
    }
}
