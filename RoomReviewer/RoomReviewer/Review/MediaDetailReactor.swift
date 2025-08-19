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
    private let dbManager: DBManager
    
    init(media: Media, networkService: NetworkService, imageProvider: ImageProviding, dbManager: DBManager) {
        self.initialState = State(media: media)
        self.networkService = networkService
        self.imageProvider = imageProvider
        self.dbManager = dbManager
    }
    
    struct State {
        var media: Media
        var backDropImageData: UIImage?
        var posterImageData: UIImage?
        var mediaDetail: MediaDetail?
        var isLoading: Bool?
        var errorType: Error?
        var isWatchlisted: Bool?
    }
    
    enum Action {
        case viewDidLoad
        case loadBackdropImage(String?)
        case loadPosterImage(String?)
        case watchlistButtonTapped
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setMediaDetail(MediaDetail)
        case setBackdropImage(UIImage?)
        case setPosterImage(UIImage?)
        case showError(Error)
        case setWatchlisted(Bool)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            let media = currentState.media
            let checkWatchlist = dbManager.checkSavedMedia(id: String(media.id))
                .asObservable()
                .map { Mutation.setWatchlisted($0) }
                .catch { .just(.showError($0)) }
            
            let fetchOthers = Observable.merge(
                self.fetchMediaCredits(),
                media.backdropPath?.isEmpty == false ? self.loadBackdropImage(media.backdropPath!) :
                    (media.posterPath.map { self.loadBackdropImage($0) } ?? .empty()),
                (media.posterPath.map { self.loadPosterImage($0) } ?? .empty())
            )
            
            return Observable.concat([
                .just(.setLoading(true)),
                Observable.merge(checkWatchlist, fetchOthers).observe(on: MainScheduler.instance),
                .just(.setLoading(false))
            ])

            
        case .loadBackdropImage(let backDropURL):
            guard let url = backDropURL else { return .empty() }
            return loadBackdropImage(url)
            
        case .loadPosterImage(let posterURL):
            guard let url = posterURL else { return .empty() }
            return loadPosterImage(url)
            
        case .watchlistButtonTapped:
            let media = currentState.media
            let isCurrentlyWatchlisted = currentState.isWatchlisted ?? false
            
            if isCurrentlyWatchlisted {
                return dbManager.deleteMedia(id: String(media.id))
                    .asObservable()
                    .observe(on: MainScheduler.instance)
                    .flatMap { _ -> Observable<Mutation> in
                        return .just(.setWatchlisted(false))
                    }
                    .catch { .just(.showError($0)) }
            } else {
                let mediaTypeString = media.mediaType.rawValue
                let releaseDate = date(from: media.releaseDate)
                
                return dbManager.createMedia(
                    id: String(media.id),
                    title: media.title,
                    type: mediaTypeString,
                    releaseDate: releaseDate,
                    watchedDate: nil
                )
                .asObservable()
                .observe(on: MainScheduler.instance)
                .flatMap { _ -> Observable<Mutation> in
                    return .just(.setWatchlisted(true))
                }
                .catch { .just(.showError($0)) }
            }
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
            
        case .setWatchlisted(let isWatchlisted):
            newState.isWatchlisted = isWatchlisted
        }
        
        return newState
    }
}

extension MediaDetailReactor {
    private func date(from string: String?) -> Date? {
        guard let dateString = string else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

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
