import Foundation
import Network
import RxSwift

protocol NetworkMonitoring {
    var isConnected: Observable<Bool> { get }
    var isCurrentlyConnected: Bool { get }
    func start()
    func stop()
}

final class NetworkMonitor: NetworkMonitoring {
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue.global(qos: .background)
    
    private let isConnectedSubject = BehaviorSubject<Bool>(value: true)
    var isConnected: Observable<Bool> {
        return isConnectedSubject.asObservable()
    }
    
    var isCurrentlyConnected: Bool {
        return monitor.currentPath.status == .satisfied
    }

    init() {
        self.monitor = NWPathMonitor()
    }

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnectedSubject.onNext(path.status == .satisfied)
        }
        monitor.start(queue: monitorQueue)
    }

    func stop() {
        monitor.cancel()
    }
}
