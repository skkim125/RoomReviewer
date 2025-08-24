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
        self.initialState = State(media: media, title: media.title, overview: media.overview, genres: API.convertGenreString(media.genreIDS).joined(separator: " / "))
        self.networkService = networkService
        self.imageProvider = imageProvider
        self.dbManager = dbManager
    }
    
    struct State {
        var media: Media
        var title: String
        var overview: String?
        var genres: String?
        var backDropImageData: UIImage?
        var posterImageData: UIImage?
        var casts: [Cast]?
        var creatorInfo: (MediaType?,[Crew]?)
        var mediaSemiInfo: String?
        var isLoading: Bool?
        var errorType: Error?
        var isWatchlisted: Bool?
        var watchedDate: Date?
        @Pulse var showSetWatchedDateAlert: Void?
        @Pulse var pushWriteReviewView: Void?
    }
    
    enum Action {
        case viewDidLoad
        case loadBackdropImage(String?)
        case loadPosterImage(String?)
        case watchlistButtonTapped
        case writeReviewButtonTapped
        case updateWatchedDate(Date)
    }
    
    enum Mutation {
        case setLoading(Bool)
        case getMediaDetail((MediaType,MediaDetail))
        case setBackdropImage(UIImage?)
        case setPosterImage(UIImage?)
        case showError(Error)
        case setWatchlisted(Bool)
        case showSetWatchedDateAlert
        case setWatchedDate(Date)
        case pushWriteReviewView
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            let media = currentState.media
            print(media.id)
            let checkWatchlist = dbManager.fetchMedia(id: media.id)
                .asObservable()
                .map {
                    if let _ = $0 {
                        Mutation.setWatchlisted(true)
                    } else {
                        Mutation.setWatchlisted(false)
                    }
                }
            
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
                return dbManager.deleteMedia(id: media.id)
                    .asObservable()
                    .observe(on: MainScheduler.instance)
                    .flatMap { _ -> Observable<Mutation> in
                        return .just(.setWatchlisted(false))
                    }
                    .catch { .just(.showError($0)) }
            } else {
                let mediaTypeString = media.mediaType.rawValue
                let releaseDate = media.releaseDate
                
                return dbManager.createMedia(
                    id: media.id,
                    title: media.title,
                    overview: media.overview,
                    type: mediaTypeString,
                    genres: media.genreIDS,
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
            
        case .writeReviewButtonTapped:
            if let _ = currentState.watchedDate {
                return .just(.pushWriteReviewView)
            } else {
                return .just(.showSetWatchedDateAlert)
            }
            
        case .updateWatchedDate(let date):
            let media = currentState.media
            
            return dbManager.updateWatchedDate(id: media.id, watchedDate: date)
                .asObservable()
                .flatMap { _ -> Observable<Mutation> in
                    return .just(.setWatchedDate(date))
                }
                .catch { .just(.showError($0)) }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let loading):
            newState.isLoading = loading
            
        case .getMediaDetail(let mediaInfo):
            let (mediaType, detail) = mediaInfo
            newState.casts = detail.cast
            newState.creatorInfo = (mediaType, detail.creator)
            
            let mediaSemiInfoItems: [String?] = [
                detail.runtimeOrEpisodeInfo,
                detail.certificate,
                detail.releaseYear
            ]
            
            newState.mediaSemiInfo = mediaSemiInfoItems.compactMap { $0 }.joined(separator: " • ")
            
        case .setBackdropImage(let image):
            newState.backDropImageData = image
            
        case .setPosterImage(let image):
            newState.posterImageData = image
            
        case .showError(let error):
            newState.errorType = error
            
        case .setWatchlisted(let isWatchlisted):
            newState.isWatchlisted = isWatchlisted
            
        case .setWatchedDate(let date):
            newState.watchedDate = date
            newState.pushWriteReviewView = ()
            
        case .pushWriteReviewView:
            newState.pushWriteReviewView = ()
            
        case .showSetWatchedDateAlert:
            newState.showSetWatchedDateAlert = ()
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
            targetType = TMDBTargetType.getMovieDetail(media.id)
            return networkService.callRequest(targetType)
                .asObservable()
                .flatMap { (result: Result<MovieDetail, Error>) -> Observable<Mutation> in
                    switch result {
                    case .success(let detail):
                        return .just(.getMediaDetail((media.mediaType, detail.toDomain())))
                    case .failure(let error):
                        return .just(.showError(error))
                    }
                }
        case .tv:
            targetType = TMDBTargetType.getTVDetail(media.id)
            return networkService.callRequest(targetType)
                .asObservable()
                .flatMap { (result: Result<TVDetail, Error>) -> Observable<Mutation> in
                    switch result {
                    case .success(let detail):
                        return .just(.getMediaDetail((media.mediaType, detail.toDomain())))
                    case .failure(let error):
                        return .just(.showError(error))
                    }
                }
        default:
            return .empty()
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
