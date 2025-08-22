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
        case setImageData(UIImage?)
    }

    struct State {
        var mediaName: String?
        var mediaPosterURL: String?
        var imageData: UIImage?
        var isLoading: Bool = false
    }

    var initialState: State
    private let imageLoader: ImageProviding

    init(media: Media, imageLoader: ImageProviding) {
        self.initialState = State(mediaName: media.title, mediaPosterURL: media.posterPath)
        self.imageLoader = imageLoader
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadImage:
            guard let url = currentState.mediaPosterURL else {
                return .just(.setImageData(nil))
            }
            let imageStream = imageLoader.fetchImage(from: url)
                .observe(on: MainScheduler.instance)
                .map { Mutation.setImageData($0) }
            
            return Observable.concat([
                .just(.setLoading(true)),
                imageStream,
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
