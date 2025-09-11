
import Foundation
import RxSwift

protocol DataFetching {
    func fetchData(request: URLRequest) -> Single<Data>
}

final class URLSessionDataFetcher: DataFetching {
    private let networkMonitor: NetworkMonitoring
    
    init(networkMonitor: NetworkMonitoring) {
        self.networkMonitor = networkMonitor
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
                    let task = URLSession.shared.dataTask(with: request) { data, response, error in
                        if let error = error {
                            single(.failure(error))
                            return
                        }
                        
                        guard let response = response as? HTTPURLResponse,
                              response.statusCode == 200 else {
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
