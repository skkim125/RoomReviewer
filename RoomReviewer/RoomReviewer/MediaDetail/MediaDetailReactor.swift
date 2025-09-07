//
//  MediaDetailReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/13/25.
//

import UIKit
import RxSwift
import ReactorKit
import CoreData

final class MediaDetailReactor: Reactor {
    var initialState: State
    private let networkService: NetworkService
    private let imageProvider: ImageProviding
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    
    init(media: Media, networkService: NetworkService, imageProvider: ImageProviding, mediaDBManager: MediaDBManager, reviewDBManager: ReviewDBManager) {
        self.initialState = State(media: media, title: media.title)
        self.networkService = networkService
        self.imageProvider = imageProvider
        self.mediaDBManager = mediaDBManager
        self.reviewDBManager = reviewDBManager
    }
    
    struct State {
        var media: Media
        var title: String
        var overview: String?
        var genres: String?
        var backDropImageData: UIImage?
        var posterImageData: UIImage?
        var casts: [Cast] = []
        var creators: [Crew] = []
        var credits: [CreditsSectionModel] = []
        var mediaSemiInfo: String?
        var isOverviewButtonVisible: Bool = false
        var isOverviewExpanded: Bool = false
        var isLoading: Bool?
        var errorType: Error?
        var isWatchlisted: Bool = false
        var watchedDate: Date?
        var mediaObjectID: NSManagedObjectID?
        var isReviewed: Bool = false
        var isStared: Bool = false
        @Pulse var showSetWatchedDateAlert: Void?
        @Pulse var pushWriteReviewView: (Media, NSManagedObjectID?)?
    }
    
    enum Action {
        case viewDidLoad
        case watchlistButtonTapped
        case watchedButtonTapped
        case writeReviewButtonTapped
        case updateWatchedDate(Date)
        case moreOverviewButtonTapped
        case starButtonTapped
        case setOverviewButtonVisible(Bool)
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setInitialData(overview: String?, genres: String?)
        case getMediaDetail(MediaDetail)
        case setBackdropImage(UIImage?)
        case setPosterImage(UIImage?)
        case showError(Error)
        case setWatchlistStatus(isWatchlisted: Bool, watchedDate: Date?, mediaObjectID: NSManagedObjectID?, isReviewed: Bool)
        case showSetWatchedDateAlert
        case setWatchedDate(Date)
        case pushWriteReviewView
        case toggleOverviewExpanded
        case setOverviewTruncatable(Bool)
        case updateStarButton(Bool)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            let media = currentState.media
            print(media.id)
            
            let setInitialData = Observable.just(Mutation.setInitialData(
                overview: media.overview,
                genres: API.convertGenreString(media.genreIDS).joined(separator: " / ")
            ))
            
            let dbResultStream = mediaDBManager.fetchMedia(id: media.id)
                .asObservable()
                .share()
            
            let watchlistStatusStream = dbResultStream.map { result -> Mutation in
                if let (objectID, isStared, watchedDate, isReviewed) = result {
                    return .setWatchlistStatus(isWatchlisted: true, watchedDate: watchedDate, mediaObjectID: objectID, isReviewed: isReviewed)
                } else {
                    return .setWatchlistStatus(isWatchlisted: false, watchedDate: nil, mediaObjectID: nil, isReviewed: false)
                }
            }
            
            let starStatusStream = dbResultStream.map { result -> Mutation in
                let isStared = result?.isStar ?? false
                return .updateStarButton(isStared)
            }
            
            let checkWatchlist = Observable.merge(watchlistStatusStream, starStatusStream)
            
            let fetchOthers = Observable.merge(
                self.fetchMediaCredits(),
                self.loadBackdropImage(media.backdropPath ?? ""),
                self.loadPosterImage(media.posterPath ?? "")
            )
            
            return Observable.concat([
                .just(.setLoading(true)),
                Observable.merge(setInitialData, checkWatchlist, fetchOthers).observe(on: MainScheduler.instance),
                .just(.setLoading(false))
            ])
            
        case .watchlistButtonTapped:
            let media = currentState.media
            let casts = currentState.casts
            let creators = currentState.creators
            let isCurrentlyWatchlisted = currentState.isWatchlisted
            let isReviewed = currentState.isReviewed
            
            if isReviewed {
                return .empty()
            } else {
                if isCurrentlyWatchlisted {
                    return mediaDBManager.deleteMedia(id: media.id)
                        .asObservable()
                        .observe(on: MainScheduler.instance)
                        .flatMap { _ -> Observable<Mutation> in
                            return .concat(.just(.setWatchlistStatus(isWatchlisted: false, watchedDate: nil, mediaObjectID: nil, isReviewed: false)), .just(.signalWatchlistUpdate))
                        }
                        .catch { .just(.showError($0)) }
                } else {
                    return mediaDBManager.createMedia(id: media.id, title: media.title, overview: media.overview, type: media.mediaType.rawValue, posterURL: media.posterPath, backdropURL: media.backdropPath, genres: media.genreIDS, releaseDate: media.releaseDate, watchedDate: nil, creators: creators, casts: casts)
                    .flatMap { _ in self.mediaDBManager.fetchMedia(id: media.id) }
                    .asObservable()
                    .observe(on: MainScheduler.instance)
                    .flatMap { result -> Observable<Mutation> in
                        if let (objectID, _, watchedDate, isReviewed) = result {
                            return .concat(.just(.setWatchlistStatus(isWatchlisted: true, watchedDate: watchedDate, mediaObjectID: objectID, isReviewed: isReviewed)), .just(.signalWatchlistUpdate))
                        }
                        return .empty()
                    }
                    .catch { .just(.showError($0)) }
                }
            }
        case .watchedButtonTapped:
            let state = currentState
            if currentState.watchedDate == nil {
                return .just(.showSetWatchedDateAlert)
            } else {
                return mediaDBManager.updateWatchedDate(id: currentState.media.id, watchedDate: nil)
                    .asObservable()
                    .flatMap { _ -> Observable<Mutation> in
                        return .just(.setWatchlistStatus(isWatchlisted: state.isWatchlisted, watchedDate: nil, mediaObjectID: state.mediaObjectID, isReviewed: state.isReviewed))
                    }
            }
            
        case .writeReviewButtonTapped:
            return .just(.pushWriteReviewView)
            
        case .updateWatchedDate(let date):
            let media = currentState.media
            
            return mediaDBManager.updateWatchedDate(id: media.id, watchedDate: date)
                .asObservable()
                .flatMap { _ -> Observable<Mutation> in
                    return .just(.setWatchedDate(date))
                }
                .catch { .just(.showError($0)) }
            
        case .moreOverviewButtonTapped:
            return .just(.toggleOverviewExpanded)
            
        case .setOverviewButtonVisible(let isTruncatable):
            return .just(.setOverviewTruncatable(isTruncatable))
            
        case .starButtonTapped:
            let media = currentState.media
            let creators = currentState.creators
            let casts = currentState.casts
            
            let starToggle = currentState.isStared ? false : true
            
            let updateIsStaredStream = mediaDBManager.updateIsStared(id: media.id, isStar: starToggle)
                .asObservable()
                .flatMap { isStar -> Observable<Mutation> in
                    return .just(.updateStarButton(isStar))
                }
            
            return updateIsStaredStream
                .catch { [weak self] error in
                    guard let self = self else { return .empty() }
                    print("\(media.title) 저장되어있지 않음")
                    return mediaDBManager.createMedia(id: media.id, title: media.title, overview: media.overview, type: media.mediaType.rawValue, posterURL: media.posterPath, backdropURL: media.backdropPath, genres: media.genreIDS, releaseDate: media.releaseDate, watchedDate: nil, creators: creators, casts: casts)
                        .asObservable()
                        .flatMap { _ in
                            return updateIsStaredStream
                        }
                }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setLoading(let loading):
            newState.isLoading = loading
            
        case .setInitialData(let overview, let genres):
            newState.overview = overview
            newState.genres = genres
            
        case .getMediaDetail(let mediaInfo):
            let detail = mediaInfo
            newState.casts = detail.cast
            newState.creators = detail.creator
            var sectionModels: [CreditsSectionModel] = []
            let creators = detail.creator.sorted(by: { $0.department ?? "" < $1.department ?? "" }).compactMap({ CreditsSectionItem.creators(item: $0) })
            let creatorsSectionModel = CreditsSectionModel.creators(item: creators)
            let casts = detail.cast.map({ CreditsSectionItem.casts(item: $0) })
            let castsSectionModel = CreditsSectionModel.casts(item: casts)
            sectionModels.append(creatorsSectionModel)
            if !casts.isEmpty {
                sectionModels.append(castsSectionModel)
            }
            newState.credits = sectionModels
            
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
            
        case .setWatchlistStatus(let isWatchlisted, let date, let objectID, let isReviewed):
            newState.isWatchlisted = isWatchlisted
            newState.watchedDate = date
            newState.mediaObjectID = objectID
            newState.isReviewed = isReviewed
            
        case .setWatchedDate(let date):
            newState.watchedDate = date
            
        case .pushWriteReviewView:
            newState.pushWriteReviewView = (currentState.media, currentState.mediaObjectID)
            
        case .showSetWatchedDateAlert:
            newState.showSetWatchedDateAlert = ()
            
        case .toggleOverviewExpanded:
            newState.isOverviewExpanded.toggle()
            
        case .setOverviewTruncatable(let isTruncatable):
            newState.isOverviewButtonVisible = isTruncatable
            
        case .updateStarButton(let isStar):
            newState.isStared = isStar
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
                        return .just(.getMediaDetail(detail.toDomain()))
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
                        return .just(.getMediaDetail(detail.toDomain()))
                    case .failure(let error):
                        return .just(.showError(error))
                    }
                }
        default:
            return .empty()
        }
    }
    
    private func loadBackdropImage(_ imagePath: String) -> Observable<Mutation> {
        if imagePath.isEmpty {
            return .just(.setBackdropImage(AppImage.emptyPosterImage))
        } else {
            return imageProvider.fetchImage(from: imagePath)
                .map { image in
                    return .setBackdropImage(image)
                }
        }
    }
    
    private func loadPosterImage(_ imagePath: String) -> Observable<Mutation> {
        if imagePath.isEmpty {
            return .just(.setPosterImage(AppImage.emptyPosterImage))
        } else {
            return imageProvider.fetchImage(from: imagePath)
                .map { image in
                    return .setPosterImage(image)
                }
        }
    }
}
