//
//  SearchMediaCollectionViewCellReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/13/25.
//

import UIKit
import RxSwift
import RxDataSources
import ReactorKit

final class SearchMediaCollectionViewCellReactor: Reactor {
    enum Action {
        case loadImage
    }

    enum Mutation {
        case setLoading(Bool)
        case setImageData(Data?)
    }

    struct State {
        var mediaName: String?
        var mediaPosterURL: String?
        var imageData: Data?
        var isLoading: Bool = false
    }

    var initialState: State
    private let imageLoader: ImageLoadService

    init(media: Media, imageLoader: ImageLoadService = ImageLoadManager()) {
        self.initialState = State(mediaName: media.title, mediaPosterURL: media.posterPath)
        self.imageLoader = imageLoader
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadImage:
            guard let url = currentState.mediaPosterURL else {
                return .just(.setImageData(nil))
            }
            return Observable.concat([
                .just(.setLoading(true)),
                imageLoader.loadImage(url)
                    .asObservable()
                    .map { result in
                        switch result {
                        case .success(let data):
                            return .setImageData(data)
                        case .failure:
                            return .setImageData(nil)
                        }
                    }
                    .observe(on: MainScheduler.instance),
                .just(.setLoading(false)),
                ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setImageData(let data):
            newState.imageData = data
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }
        return newState
    }
}
