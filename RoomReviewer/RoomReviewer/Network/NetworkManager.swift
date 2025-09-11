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
    private let dataFetcher: DataFetching
    
    init(dataFetcher: DataFetching) {
        self.dataFetcher = dataFetcher
    }
    
    func callRequest<T: Decodable>(_ target: TargetType) -> Single<Result<T, Error>> {
        do {
            let request = try target.asURLRequest()
            
            return dataFetcher.fetchData(request: request)
                .map { data -> Result<T, Error> in
                    do {
                        let decodedData = try JSONDecoder().decode(T.self, from: data)
                        return .success(decodedData)
                    } catch {
                        return .failure(NetworkError.decodingError)
                    }
                }
        } catch {
            return .just(.failure(error))
        }
    }
}

final class MockNetworkManager: NetworkService {
    var mockResult: Result<Data, Error>?
    var mockMovieResult: Result<Data, Error>?
    var mockTVResult: Result<Data, Error>?

    func callRequest<T: Decodable>(_ target: TargetType) -> Single<Result<T, Error>> {
        let selectedResult: Result<Data, Error>?

        switch target {
        case TMDBTargetType.movie:
            selectedResult = mockMovieResult ?? mockResult
        case TMDBTargetType.tv:
            selectedResult = mockTVResult ?? mockResult
        default:
            selectedResult = mockResult
        }

        return Single.create { single in
            guard let result = selectedResult else {
                single(.success(.failure(MockError.noMockData)))
                return Disposables.create()
            }

            switch result {
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    single(.success(.success(decoded)))
                } catch {
                    single(.success(.failure(error)))
                }
            case .failure(let error):
                single(.success(.failure(error)))
            }

            return Disposables.create()
        }
    }

    enum MockError: Error {
        case noMockData
    }
}


