//
//  NetworkManager.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/13/25.
//

import Foundation
import RxSwift

protocol NetworkService {
    func callRequest<T: Decodable>(_ target: TargetType) -> Single<Result<T, Error>>
}

final class NetworkManager: NetworkService {
    func callRequest<T: Decodable>(_ target: TargetType) -> Single<Result<T, Error>> {
        return Single.create { single in
            do {
                let request = try target.asURLRequest()
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        return single(.success(.failure(error)))
                    }
                    
                    guard let response = response as? HTTPURLResponse,
                          200 == response.statusCode else {
                        return single(.success(.failure(NetworkError.invalidResponse)))
                    }
                    
                    guard let data = data else {
                        return single(.success(.failure(NetworkError.invalidData)))
                    }
                    
                    do {
                        let decodedData = try JSONDecoder().decode(T.self, from: data)
                        return single(.success(.success(decodedData)))
                    } catch {
                        return single(.success(.failure(NetworkError.decodingError)))
                    }
                }
                .resume()
                
            } catch {
                single(.success(.failure(error)))
            }
            
            return Disposables.create()
        }
    }
}
