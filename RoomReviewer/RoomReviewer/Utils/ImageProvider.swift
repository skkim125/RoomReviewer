//
//  ImageProvider.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/15/25.
//

import UIKit
import RxSwift

protocol ImageProviding {
    func fetchImage(urlString: String?) -> Observable<Data?>
}

final class ImageProvider: ImageProviding {
    private let memoryCache = NSCache<NSString, NSData>()
    private let fileManager: ImageFileManaging
    private let dataFetcher: DataFetching
    
    init(fileManager: ImageFileManaging, dataFetcher: DataFetching) {
        self.fileManager = fileManager
        self.dataFetcher = dataFetcher
        memoryCache.totalCostLimit = 150 * 1024 * 1024
    }
    
    func fetchImage(urlString: String?) -> Observable<Data?> {
        guard let urlString = urlString, let url = URL(string: API.tmdbImageURL + urlString) else {
            return .just(nil)
        }
        
        let cacheKey = NSString(string: url.absoluteString)
        
        if let cachedData = memoryCache.object(forKey: cacheKey) {
            return .just(cachedData as Data)
        }
        
        return fileManager.loadImage(urlString: urlString)
            .flatMap { [weak self] permanentData -> Observable<Data?> in
                guard let self = self else { return .empty() }
                
                if let data = permanentData {
                    self.memoryCache.setObject(data as NSData, forKey: cacheKey)
                    return .just(data)
                }
                
                let request = URLRequest(url: url)
                return self.dataFetcher.fetchData(request: request)
                    .asObservable()
                    .map { originalData -> Data? in
                        guard let image = originalData.downsampledImage(),
                              let optimizedData = image.jpegData(compressionQuality: 0.8) else {
                            return nil
                        }
                        
                        self.memoryCache.setObject(optimizedData as NSData, forKey: cacheKey)
                        
                        return optimizedData
                    }
                    .catchAndReturn(nil)
            }
    }
}
