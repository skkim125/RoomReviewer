//
//  HomeTVCollectionViewCellReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/16/25.
//

import UIKit
import RxSwift
import ReactorKit

final class HomeMediaCollectionViewCellReactor: Reactor {
    enum Action {
        case loadImage
    }

    enum Mutation {
        case setLoading(Bool)
        case setImage(Data?)
    }

    struct State {
        var mediaName: String?
        var mediaPosterURL: String?
        var image: Data?
        var isLoading: Bool = false
    }

    var initialState: State
    private let imageLoader: ImageLoadService

    init(media: Media, imageLoader: ImageLoadService) {
        self.initialState = State(mediaName: media.title, mediaPosterURL: media.posterPath)
        self.imageLoader = imageLoader
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadImage:
            guard let url = currentState.mediaPosterURL else {
                return .just(.setImage(nil))
            }
            return Observable.concat([
                .just(.setLoading(true)),
                imageLoader.loadImage(url)
                    .asObservable()
                    .compactMap { result in
                        switch result {
                        case .success(let data):
                            return data
                        case .failure:
                            return nil
                        }
                    }
                    .observe(on: MainScheduler.instance)
                    .map { Mutation.setImage($0) },
                .just(.setLoading(false)),
                ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setImage(let image):
            newState.image = image
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }
        return newState
    }
}
