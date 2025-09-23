
import Foundation
import RxSwift

protocol DataFetching {
    func fetchData(request: URLRequest) -> Single<Data>
}

final class URLSessionDataFetcher: DataFetching {
    private let networkMonitor: NetworkMonitoring
    private let session: URLSession
    
    init(networkMonitor: NetworkMonitoring) {
        self.networkMonitor = networkMonitor
        
        let configuration = URLSessionConfiguration.default
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 100MB 메모리 캐시
            diskCapacity: 200 * 1024 * 1024, // 200MB 디스크 캐시
            diskPath: "network_cache"
        )
        
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        
        session = URLSession(configuration: configuration)
    }
    
    func fetchData(request: URLRequest) -> Single<Data> {
        return networkMonitor.isConnected
            .take(1)
            .asSingle()
            .flatMap { isConnected -> Single<Data> in
                if !isConnected {
                    return .error(NetworkError.offline)
                }
                
                return Single.create { single in
                    let task = self.session.dataTask(with: request) { data, response, error in
                        if let error = error {
                            if let urlError = error as? URLError, urlError.code == .timedOut {
                                single(.failure(NetworkError.timeout))
                            } else {
                                single(.failure(error))
                            }
                            return
                        }

                        guard let response = response as? HTTPURLResponse else {
                            single(.failure(NetworkError.invalidResponse))
                            return
                        }

                        switch response.statusCode {
                        case 200:
                            break
                        case 429:
                            single(.failure(NetworkError.tooManyRequests))
                            return
                        case 500:
                            single(.failure(NetworkError.serverError))
                            return
                        case 502:
                            single(.failure(NetworkError.badGateway))
                            return
                        case 503:
                            single(.failure(NetworkError.serviceUnavailable))
                            return
                        default:
                            single(.failure(NetworkError.invalidResponse))
                            return
                        }
                        
                        guard let data = data else {
                            single(.failure(NetworkError.invalidData))
                            return
                        }
                        
                        single(.success(data))
                    }
                    
                    task.resume()
                    
                    return Disposables.create {
                        task.cancel()
                    }
                }
            }
    }
}
