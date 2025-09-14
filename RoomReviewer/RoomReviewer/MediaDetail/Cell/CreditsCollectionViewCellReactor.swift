//
//  CreditsCollectionViewCellReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/21/25.
//

import UIKit
import ReactorKit
import RxSwift

final class CreditsCollectionViewCellReactor: Reactor {
    enum Action {
        case loadImage
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setImage(UIImage?)
    }
    
    struct State {
        let name: String
        let character: String?
        let profilePath: String?
        var profileImage: UIImage?
        var isLoading: Bool = false
    }
    
    var initialState: State
    private let imageLoader: ImageProviding
    
    init(name: String, role: String?, profilePath: String?, imageLoader: ImageProviding) {
        self.initialState = State(
            name: name,
            character: role,
            profilePath: profilePath
        )
        self.imageLoader = imageLoader
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadImage:
            guard let path = currentState.profilePath else {
                return .just(.setImage(AppImage.personImage))
            }
            
            let imageStream = imageLoader.fetchImage(urlString: path)
                .asObservable()
                .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
                .map { image -> Mutation in
                    return Mutation.setImage(image ?? AppImage.personImage)
                }
            
            return Observable.concat([
                .just(.setLoading(true)),
                imageStream,
                .just(.setLoading(false))
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setImage(let image):
            newState.profileImage = image
        }
        return newState
    }
}
