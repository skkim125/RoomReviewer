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
            
            return imageFileManager.loadImage(urlString: url)
                .flatMap { [weak self] localImage -> Observable<Mutation> in
                    guard let self = self else { return .empty()
                    }
                    if let image = localImage {
                        return .just(.setImage(image))
                    } else {
                        let networkImageStream = self.imageProvider.fetchImage(urlString: url)
                            .do(onNext: { image in
                                guard let image = image, let data = image.pngData() else { return }
                                self.imageFileManager.saveImage(image: data, urlString: url)
                            })
                            .map { Mutation.setImage($0) }
                        
                        return Observable.concat([
                            .just(.setLoading(true)),
                            networkImageStream,
                            .just(.setLoading(false)),
                        ])
                    }
                }
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
