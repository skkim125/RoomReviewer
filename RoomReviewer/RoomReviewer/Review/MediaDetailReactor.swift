//
//  MediaDetailReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/13/25.
//

import UIKit
import RxSwift
import ReactorKit

final class MediaDetailReactor: Reactor {
    var initialState: State
    private let networkService: NetworkService
    private let imageProvider: ImageProviding
    
    init(media: Media, networkService: NetworkService, imageProvider: ImageProviding) {
        initialState = State(media: media)
        self.networkService = networkService
        self.imageProvider = imageProvider
    }
    
    struct State {
        var media: Media
        var backDropImageData: UIImage?
        var posterImageData: UIImage?
        var mediaDetail: MediaDetail?
        var isLoading: Bool?
        var errorType: Error?
    }
    
    enum Action {
        case viewDidLoad
        case loadBackdropImage(String?)
        case loadPosterImage(String?)
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setMediaDetail(MediaDetail)
        case setBackdropImage(UIImage?)
        case setPosterImage(UIImage?)
        case showError(Error)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            let media = currentState.media
            
            var tasks = [fetchMediaCredits()]
            
            if let backdropPath = media.backdropPath, !backdropPath.isEmpty {
                tasks.append(loadBackdropImage(backdropPath))
            }
            
            if let posterPath = media.posterPath, !posterPath.isEmpty {
                tasks.append(loadPosterImage(posterPath))
            }
            
            return Observable.concat([
                .just(.setLoading(true)),
                Observable.merge(tasks)
                    .observe(on: MainScheduler.instance),
                .just(.setLoading(false))
            ])
            
        case .loadBackdropImage(let backDropURL):
            guard let url = backDropURL else { return .empty() }
            return loadBackdropImage(url)
            
        case .loadPosterImage(let posterURL):
            guard let url = posterURL else { return .empty() }
            return loadPosterImage(url)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let loading):
            newState.isLoading = loading
            
        case .setMediaDetail(let detail):
            newState.mediaDetail = detail
            
        case .setBackdropImage(let image):
            newState.backDropImageData = image
            
        case .setPosterImage(let image):
            newState.posterImageData = image
            
        case .showError(let error):
            newState.errorType = error
        }
        
        return newState
    }
}

extension MediaDetailReactor {
    private func fetchMediaCredits() -> Observable<Mutation> {
        let targetType: TMDBTargetType
        let media = currentState.media
        
        switch media.mediaType {
        case .movie:
            targetType = TMDBTargetType.movieCredits(media.id)
        case .tv:
            targetType = TMDBTargetType.tvCredits(media.id)
        default:
            return .empty()
        }
        
        return networkService.callRequest(targetType)
            .asObservable()
            .flatMap { (result: Result<Credits, Error>) -> Observable<Mutation> in
                switch result {
                case .success(let credits):
                    return .just(.setMediaDetail(MediaDetail(mediaInfo: media, mediaCredits: credits)))
                case .failure(let error):
                    return .just(.showError(error))
                }
            }
    }
    
    private func loadBackdropImage(_ imagePath: String) -> Observable<Mutation> {
        return imageProvider.fetchImage(from: imagePath)
            .map { image in
                return .setBackdropImage(image)
            }
    }
    
    private func loadPosterImage(_ imagePath: String) -> Observable<Mutation> {
        return imageProvider.fetchImage(from: imagePath)
            .map { image in
                return .setPosterImage(image)
            }
    }
}
