//
//  MediaDetailReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/13/25.
//

import Foundation
import RxSwift
import ReactorKit

final class MediaDetailReactor: Reactor {
    var initialState: State
    private let networkService: NetworkService
    private let imageLoader: ImageLoadService
    
    init(media: Media, networkService: NetworkService, imageLoader: ImageLoadService) {
        initialState = State(media: media)
        self.networkService = networkService
        self.imageLoader = imageLoader
    }
    
    struct State {
        var media: Media
        var backDropImage: Data?
        var posterImage: Data?
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
        case setBackdropImage(Data?)
        case setPosterImage(Data?)
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
                Observable.merge(tasks),
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
            newState.backDropImage = image
            
        case .setPosterImage(let image):
            newState.posterImage = image
            
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
        return loadImage(imagePath: imagePath)
            .map { image in
                return .setBackdropImage(image)
            }
    }
    
    private func loadPosterImage(_ imagePath: String) -> Observable<Mutation> {
        return loadImage(imagePath: imagePath)
            .map { image in
                return .setPosterImage(image)
            }
    }
    
    private func loadImage(imagePath: String) -> Observable<Data?> {
        return imageLoader.loadImage(imagePath)
            .asObservable()
            .map { result in
                switch result {
                case .success(let image):
                    return image
                case .failure(let error):
                    print("이미지 로드 실패: \(error)")
                    return nil
                }
            }
    }
}
