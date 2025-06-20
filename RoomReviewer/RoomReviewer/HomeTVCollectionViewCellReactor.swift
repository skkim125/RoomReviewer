//
//  HomeTVCollectionViewCellReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/16/25.
//

import UIKit
import RxSwift
import ReactorKit

final class HomeTVCollectionViewCellReactor: Reactor {
    enum Action {
        case loadImage
    }

    enum Mutation {
        case setLoading(Bool)
        case setImage(UIImage)
    }

    struct State {
        var tvName: String?
        var tvPosterURL: String?
        var image: UIImage?
        var isLoading: Bool = false
    }

    var initialState: State
    private let imageLoader: ImageLoadService

    init(tv: TV, imageLoader: ImageLoadService = ImageLoadManager()) {
        self.initialState = State(tvName: tv.originalName, tvPosterURL: tv.posterPath)
        self.imageLoader = imageLoader
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadImage:
            guard let url = currentState.tvPosterURL else {
                return .just(.setImage(UIImage(systemName: "photo.fill")!))
            }
            return Observable.concat([
                .just(.setLoading(true)),
                imageLoader.loadImage(url)
                    .asObservable()
                    .compactMap { result in
                        switch result {
                        case .success(let data):
                            return UIImage(data: data)
                        case .failure:
                            return UIImage(systemName: "photo.fill")
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
