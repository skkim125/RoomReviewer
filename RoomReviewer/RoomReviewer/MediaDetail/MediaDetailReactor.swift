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
    private let imageFileManager: ImageFileManaging
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    private let networkMonitor: NetworkMonitoring
    private var disposeBag = DisposeBag()
    
    deinit {
        print("MediaDetailReactor deinit")
    }
    
    init(media: Media, networkService: NetworkService, imageProvider: ImageProviding, imageFileManager: ImageFileManaging, mediaDBManager: MediaDBManager, reviewDBManager: ReviewDBManager, networkMonitor: NetworkMonitoring) {
        self.initialState = State(media: media, title: media.title)
        self.networkService = networkService
        self.imageProvider = imageProvider
        self.imageFileManager = imageFileManager
        self.mediaDBManager = mediaDBManager
        self.reviewDBManager = reviewDBManager
        self.networkMonitor = networkMonitor
    }
    
    struct State {
        enum ViewState: Equatable {
            case loading
            case loaded
        }
        var viewState: ViewState = .loaded
        
        var media: Media
        var title: String
        var overview: String?
        var genres: String?
        var backDropImageData: UIImage?
        var posterImageData: UIImage?
        var casts: [Cast] = []
        var creators: [Crew] = []
        var credits: [CreditsSectionModel] = []
        var releaseYear: String?
        var certificate: String?
        var runtimeOrEpisodeInfo: String?
        var isOverviewButtonVisible: Bool = false
        var isOverviewExpanded: Bool = false
        var isWatchlisted: Bool = false
        var watchedDate: Date?
        var mediaObjectID: NSManagedObjectID?
        var isReviewed: Bool = false
        var isStared: Bool = false
        var mediaSemiInfo: String {
            var components: [String] = []
            
            if let year = releaseYear, !year.isEmpty, year != "정보 없음" {
                components.append(year)
            }
            
            if let cert = certificate, !cert.isEmpty, cert != "정보 없음", cert != "업데이트 예정" {
                components.append(cert)
            }
            
            if let runtime = runtimeOrEpisodeInfo, !runtime.isEmpty, runtime != "정보 없음", runtime != "0분" {
                components.append(runtime)
            }
            
            return components.joined(separator: " · ")
        }
        @Pulse var showSetWatchedDateAlert: Void?
        @Pulse var pushWriteReviewView: (Media, ReviewEntity?)?
        @Pulse var showNetworkErrorAndDismiss: Void?
        @Pulse var error: Error?
    }
    
    enum Action {
        case viewDidLoad
        case viewWillAppear
        case watchlistButtonTapped
        case watchedButtonTapped
        case writeReviewButtonTapped
        case updateWatchedDate(Date)
        case moreOverviewButtonTapped
        case starButtonTapped
        case setOverviewButtonVisible(Bool)
    }
    
    enum Mutation {
        case setViewState(State.ViewState)
        case getMediaDetail(MediaDetail)
        case setBackdropImage(UIImage?)
        case setPosterImage(UIImage?)
        case setWatchlistStatus(isWatchlisted: Bool, isStared: Bool, watchedDate: Date?, mediaObjectID: NSManagedObjectID?, isReviewed: Bool)
        case showSetWatchedDateAlert
        case setWatchedDate(Date)
        case pushWriteReviewView(Media, ReviewEntity?)
        case toggleOverviewExpanded
        case setOverviewTruncatable(Bool)
        case updateStarButton(Bool)
        case showNetworkErrorAndDismiss
        case showError(Error)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            let media = currentState.media
            
            let dbStatusStream = mediaDBManager.fetchMedia(id: media.id)
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .asObservable()
                .compactMap { result -> Mutation? in
                    if let (isWatchlist, objectID, isStared, watchedDate, isReviewed) = result {
                        return .setWatchlistStatus(isWatchlisted: isWatchlist, isStared: isStared, watchedDate: watchedDate, mediaObjectID: objectID, isReviewed: isReviewed)
                    } else {
                        return .setWatchlistStatus(isWatchlisted: false, isStared: false, watchedDate: nil, mediaObjectID: nil, isReviewed: false)
                    }
                }
                .catch { error in
                    return .just(.showError(error))
                }
            
            let imageStream = Observable.merge(
                self.loadBackdropImage(currentState.media.backdropPath)
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated)),
                self.loadPosterImage(currentState.media.posterPath)
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            )
            
            let detailFetchStream = mediaDBManager.fetchMediaEntity(id: media.id)
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .asObservable()
                .flatMap { [weak self] entity -> Observable<Mutation> in
                    guard let self = self else { return .empty() }
                    if let entity = entity {
                        let mediaDetail = entity.toMediaDetail()
                        return .concat([
                            .just(.getMediaDetail(mediaDetail)),
                            .just(.setViewState(.loaded))
                        ])
                    } else {
                        if !self.networkMonitor.isCurrentlyConnected {
                            return .just(.showNetworkErrorAndDismiss)
                        }
                        
                        return Observable.concat([
                            .just(.setViewState(.loading)),
                            self.fetchMediaCredits(),
                            .just(.setViewState(.loaded)),
                        ])
                    }
                }
            
            return Observable.merge(detailFetchStream, dbStatusStream, imageStream)
                .observe(on: MainScheduler.instance)
            
        case .viewWillAppear:
            let media = currentState.media
            return mediaDBManager.fetchMedia(id: media.id)
                .asObservable()
                .compactMap { result -> Mutation? in
                    if let (isWatchlist, objectID, isStared, watchedDate, isReviewed) = result {
                        return .setWatchlistStatus(isWatchlisted: isWatchlist, isStared: isStared, watchedDate: watchedDate, mediaObjectID: objectID, isReviewed: isReviewed)
                    }
                    return nil
                }
        
        case .watchlistButtonTapped:
            let media = currentState.media
            let casts = currentState.casts
            let creators = currentState.creators
            let isCurrentlyWatchlisted = currentState.isWatchlisted
            
            if isCurrentlyWatchlisted {
                if let posterPath = media.posterPath {
                    imageFileManager.deleteImage(urlString: posterPath)
                }
                if let backdropPath = media.backdropPath {
                    imageFileManager.deleteImage(urlString: backdropPath)
                }
                
                return mediaDBManager.deleteMedia(id: media.id)
                    .asObservable()
                    .flatMap { _ -> Observable<Mutation> in
                        return .just(.setWatchlistStatus(isWatchlisted: false, isStared: false, watchedDate: nil, mediaObjectID: nil, isReviewed: false))
                    }
                    .catch { error in
                        print("Error deleting media: \(error)")
                        return .just(.showError(DatabaseError.deleteFailed))
                    }
                
            } else {
                let posterSaveStream = imageProvider.fetchImage(urlString: media.posterPath)
                    .flatMap { [weak self] image -> Observable<Void> in
                        guard let self = self,
                              let image = image,
                              let url = media.posterPath,
                              let data = image.jpegData(compressionQuality: 1.0) else {
                            return .just(())
                        }
                        self.imageFileManager.saveImage(image: data, urlString: url)
                        return .just(())
                    }
                
                let backdropSaveStream = imageProvider.fetchImage(urlString: media.backdropPath)
                    .flatMap { [weak self] image -> Observable<Void> in
                        guard let self = self,
                              let image = image,
                              let url = media.backdropPath,
                              let data = image.jpegData(compressionQuality: 1.0) else {
                            return .just(())
                        }
                        self.imageFileManager.saveImage(image: data, urlString: url)
                        return .just(())
                    }

                
                let createMediaStream = mediaDBManager.createMedia(id: media.id, title: media.title, overview: media.overview, type: media.mediaType.rawValue, posterURL: media.posterPath, backdropURL: media.backdropPath, genres: media.genreIDS, releaseDate: media.releaseDate, watchedDate: nil, creators: creators, casts: casts, addedDate: Date(), certificate: currentState.certificate, runtimeOrEpisodeInfo: currentState.runtimeOrEpisodeInfo)
                    .flatMap { _ in self.mediaDBManager.fetchMedia(id: media.id) }
                    .asObservable()
                    .flatMap { result -> Observable<Mutation> in
                        if let (isWatchlist, objectID, isStared, watchedDate, isReviewed) = result {
                            return .just(.setWatchlistStatus(isWatchlisted: isWatchlist, isStared: isStared, watchedDate: watchedDate, mediaObjectID: objectID, isReviewed: isReviewed))
                        }
                        return .empty()
                    }
                
                return Observable.zip(posterSaveStream, backdropSaveStream)
                    .flatMap { _ in createMediaStream }
                    .catch { error in
                        print("Error creating media: \(error)")
                        return .just(.showError(DatabaseError.saveFailed))
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
                        return .just(.setWatchlistStatus(isWatchlisted: state.isWatchlisted, isStared: state.isStared, watchedDate: nil, mediaObjectID: state.mediaObjectID, isReviewed: state.isReviewed))
                    }
            }
            
        case .writeReviewButtonTapped:
            let media = currentState.media
            let existingReview = reviewDBManager.fetchReview(id: media.id)
            return .just(.pushWriteReviewView(media, existingReview))
            
        case .updateWatchedDate(let date):
            let media = currentState.media
            
            return mediaDBManager.updateWatchedDate(id: media.id, watchedDate: date)
                .asObservable()
                .flatMap { _ -> Observable<Mutation> in
                    return .just(.setWatchedDate(date))
                }
                .catch { error in
                    print("Error updating watched date: \(error)")
                    return .just(.showError(DatabaseError.updateFailed))
                }
            
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
                .catch { [weak self] error -> Observable<Mutation> in
                    guard let self = self else { return .empty() }
                    print("\(media.title) 저장되어있지 않음")
                    return mediaDBManager.createMedia(id: media.id, title: media.title, overview: media.overview, type: media.mediaType.rawValue, posterURL: media.posterPath, backdropURL: media.backdropPath, genres: media.genreIDS, releaseDate: media.releaseDate, watchedDate: nil, creators: creators, casts: casts, addedDate: nil, certificate: self.currentState.certificate, runtimeOrEpisodeInfo: self.currentState.runtimeOrEpisodeInfo)
                        .asObservable()
                        .flatMap { _ in
                            return updateIsStaredStream
                        }
                        .catch { createError in
                            print("Error creating media after star update failure: \(createError)")
                            return .just(.showError(DatabaseError.saveFailed))
                        }
                }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setViewState(let viewState):
            newState.viewState = viewState
            
        case .getMediaDetail(let mediaInfo):
            let detail = mediaInfo
            newState.overview = detail.overview
            newState.genres = detail.genres.joined(separator: " / ")
            newState.casts = detail.cast
            newState.creators = detail.creator
            var sectionModels: [CreditsSectionModel] = []
            let creators = detail.creator.sorted(by: { $0.department ?? "" < $1.department ?? "" }).compactMap({ CreditsSectionItem.creators(item: $0) })
            if !creators.isEmpty {
                let creatorsSectionModel = CreditsSectionModel.creators(item: creators)
                sectionModels.append(creatorsSectionModel)
            }
            
            let casts = detail.cast.map({ CreditsSectionItem.casts(item: $0) })
            if !casts.isEmpty {
                let castsSectionModel = CreditsSectionModel.casts(item: casts)
                sectionModels.append(castsSectionModel)
            }
            newState.credits = sectionModels
            
            newState.releaseYear = detail.releaseYear
            newState.certificate = detail.certificate
            newState.runtimeOrEpisodeInfo = detail.runtimeOrEpisodeInfo
            
        case .setBackdropImage(let image):
            newState.backDropImageData = image
            
        case .setPosterImage(let image):
            newState.posterImageData = image
            
        case .setWatchlistStatus(let isWatchlisted, let isStared, let date, let objectID, let isReviewed):
            newState.isWatchlisted = isWatchlisted
            newState.watchedDate = date
            newState.mediaObjectID = objectID
            newState.isStared = isStared
            newState.isReviewed = isReviewed
            
        case .setWatchedDate(let date):
            newState.watchedDate = date
            
        case .pushWriteReviewView(let media, let reviewEntity):
            newState.pushWriteReviewView = (media, reviewEntity)
            
        case .showSetWatchedDateAlert:
            newState.showSetWatchedDateAlert = ()
            
        case .toggleOverviewExpanded:
            newState.isOverviewExpanded.toggle()
            
        case .setOverviewTruncatable(let isTruncatable):
            newState.isOverviewButtonVisible = isTruncatable
            
        case .updateStarButton(let isStar):
            newState.isStared = isStar
            
        case .showNetworkErrorAndDismiss:
            newState.showNetworkErrorAndDismiss = ()
        case .showError(let error):
            newState.error = error
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
                        if let networkError = error as? NetworkError, networkError == .offline {
                            return .just(.showNetworkErrorAndDismiss)
                        } else if let networkError = error as? NetworkError {
                            return .just(.showError(networkError))
                        } else {
                            return .just(.showError(NetworkError.commonError))
                        }
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
                        if let networkError = error as? NetworkError, networkError == .offline {
                            return .just(.showNetworkErrorAndDismiss)
                        } else if let networkError = error as? NetworkError {
                            return .just(.showError(networkError))
                        } else {
                            return .just(.showError(NetworkError.commonError))
                        }
                    }
                }
        default:
            return .empty()
        }
    }
    
    private func loadBackdropImage(_ imagePath: String?) -> Observable<Mutation> {
        guard let imagePath = imagePath, !imagePath.isEmpty else {
            return .just(.setBackdropImage(AppImage.emptyPosterImage))
        }
        
        return imageProvider.fetchImage(urlString: imagePath)
                .map { .setBackdropImage($0) }
                .catchAndReturn(.setBackdropImage(nil))
    }
    
    private func loadPosterImage(_ imagePath: String?) -> Observable<Mutation> {
        guard let imagePath = imagePath, !imagePath.isEmpty else {
            return .just(.setPosterImage(AppImage.emptyPosterImage))
        }
        
        return imageProvider.fetchImage(urlString: imagePath)
            .map { .setPosterImage($0) }
            .catchAndReturn(.setPosterImage(nil))
    }
}
