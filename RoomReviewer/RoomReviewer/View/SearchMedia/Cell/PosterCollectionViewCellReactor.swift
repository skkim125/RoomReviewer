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

final class PosterCollectionViewCellReactor: Reactor {
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

    init(media: Media, imageProvider: ImageProviding) {
        self.initialState = State(mediaName: media.title, mediaPosterURL: media.posterPath)
        self.imageProvider = imageProvider
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadImage:
            guard let url = currentState.mediaPosterURL else {
                return .just(.setImage(AppImage.emptyPosterImage))
            }
            
            let imageURL = API.tmdbImageURL + url
            let imageStream = imageProvider.fetchImage(urlString: imageURL)
                .map { data -> UIImage in
                    guard let data = data, let image = UIImage(data: data) else {
                        return AppImage.emptyPosterImage
                    }
                    return image
                }
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
        case .setImage(let image):
            newState.imageData = image
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }
        return newState
    }
}
