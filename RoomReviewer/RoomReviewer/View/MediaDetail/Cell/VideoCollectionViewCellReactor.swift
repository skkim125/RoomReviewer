//
//  VideoCollectionViewCellReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/25/25.
//

import UIKit
import ReactorKit
import RxSwift

final class VideoCollectionViewCellReactor: Reactor {
    enum Action {
        case loadImage
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setImage(UIImage?)
    }
    
    struct State {
        let videoName: String?
        let videoKey: String?
        var videoThumnailImage: UIImage?
        var isLoading: Bool = false
    }
    
    var initialState: State
    private let imageLoader: ImageProviding
    
    init(videoName: String?, videoKey: String?, imageLoader: ImageProviding) {
        self.initialState = State(
            videoName: videoName,
            videoKey: videoKey
        )
        self.imageLoader = imageLoader
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadImage:
            guard let videoKey = currentState.videoKey else {
                return .just(.setImage(AppImage.personImage))
            }
            let thumnailLink = API.youtubeThumnailURL + videoKey + "/hqdefault.jpg"
            print("thumnailLink", thumnailLink)
            let imageStream = imageLoader.fetchImage(urlString: thumnailLink)
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
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setImage(let image):
            newState.videoThumnailImage = image
        }
        return newState
    }
}
