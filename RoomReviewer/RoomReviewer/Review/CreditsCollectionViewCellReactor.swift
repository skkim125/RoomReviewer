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
        let character: String
        let profilePath: String?
        var profileImage: UIImage?
        var isLoading: Bool = false
    }
    
    var initialState: State
    private let imageLoader: ImageProviding
    
    init(cast: Cast, imageLoader: ImageProviding) {
        self.initialState = State(
            name: cast.name,
            character: cast.character ?? "",
            profilePath: cast.profilePath
        )
        self.imageLoader = imageLoader
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadImage:
            guard let path = currentState.profilePath else {
                let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .ultraLight)
                let emptyImage = UIImage(systemName: "person", withConfiguration: config)
                return .just(.setImage(emptyImage))
            }
            
            let imageStream = imageLoader.fetchImage(from: path)
                .asObservable()
                .map { Mutation.setImage($0) }
            
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
