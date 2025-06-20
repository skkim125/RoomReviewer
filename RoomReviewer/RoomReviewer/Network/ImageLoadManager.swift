//
//  ImageLoadManager.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/16/25.
//

import Foundation
import RxSwift

protocol ImageLoadService {
    func loadImage(_ urlString: String?) -> Single<Result<Data, Error>>
}

final class ImageLoadManager: ImageLoadService {
    func loadImage(_ urlString: String?) -> Single<Result<Data, Error>> {
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
}

final class MockImageLoadService: ImageLoadService {
    var loadImageResult: Result<Data, Error> = .failure(NetworkError.commonError)
    var loadImageCallCount = 0
    
    func loadImage(_ urlString: String?) -> Single<Result<Data, Error>> {
        loadImageCallCount += 1
        return Single.just(loadImageResult)
    }
}
