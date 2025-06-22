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
                    
                    do {
                        let decodedData = try JSONDecoder().decode(T.self, from: data)
                        return single(.success(.success(decodedData)))
                    } catch {
                        return single(.success(.failure(NetworkError.decodingError)))
                    }
                }
                
                task.resume()
                
                return Disposables.create() {
                    task.cancel()
                }
                
            } catch {
                single(.success(.failure(error)))
            }
            
            return Disposables.create()
        }
    }
}

final class MockNetworkManager: NetworkService {
    var mockResult: Result<Data, Error> = .failure(NetworkError.decodingError)
    
    func callRequest<T: Decodable>(_ target: TargetType) -> Single<Result<T, Error>> {
        return Single.create { single in
            switch self.mockResult {
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    single(.success(.success(decoded)))
                } catch {
                    print(error)
                    single(.success(.failure(error)))
                }
            case .failure(let error):
                print(error)
                single(.success(.failure(error)))
            }
            return Disposables.create()
        }
    }
}
