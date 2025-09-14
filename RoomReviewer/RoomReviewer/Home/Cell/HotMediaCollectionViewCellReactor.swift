//
//  HotTVCollectionViewCellReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/16/25.
//

import UIKit
import RxSwift
import ReactorKit

final class HotMediaCollectionViewCellReactor: Reactor {
    enum Action {
        case loadImage
    }

    enum Mutation {
        case setLoading(Bool)
        case setImage(UIImage?)
    }

    struct State {
        var mediaName: String?
        var mediaPosterURL: String?
        var imageData: UIImage?
        var isLoading: Bool = false
    }

    var initialState: State
    private let imageProvider: ImageProviding
    private let imageFileManager: ImageFileManaging

    init(media: Media, imageProvider: ImageProviding, imageFileManager: ImageFileManaging) {
        self.initialState = State(mediaName: media.title, mediaPosterURL: media.posterPath)
        self.imageProvider = imageProvider
        self.imageFileManager = imageFileManager
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadImage:
            guard let url = currentState.mediaPosterURL else {
                return .just(.setImage(AppImage.emptyPosterImage))
            }
            
            let imageStream = imageProvider.fetchImage(urlString: url)
                .map { Mutation.setImage($0 ?? AppImage.emptyPosterImage) }
            
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
        case .setImage(let image):
            newState.imageData = image
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }
        return newState
    }
}
