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
        var isEssentialDataLoaded: Bool = false
        var areImagesLoaded: Bool = false

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
        var processingAction: ProcessingAction = .none

        enum ProcessingAction: Equatable {
            case none
            case watchlist
            case updateWatchedDate
            case star
        }

        var mediaSemiInfo: String {
            var components: [String] = []
            if let year = releaseYear, !year.isEmpty, year != "정보 없음" { components.append(year) }
            if let cert = certificate, !cert.isEmpty, cert != "정보 없음", cert != "업데이트 예정" { components.append(cert) }
            if let runtime = runtimeOrEpisodeInfo, !runtime.isEmpty, runtime != "정보 없음", runtime != "0분" { components.append(runtime) }
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
        case setEssentialDataLoaded(Bool)
        case setImagesLoaded(Bool)
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
        case setProcessingAction(State.ProcessingAction)
        case showNetworkErrorAndDismiss
        case showError(Error)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            let media = currentState.media
            let mutationScheduler = SerialDispatchQueueScheduler(qos: .userInitiated)

            let dbStatusStream = mediaDBManager.fetchMedia(id: media.id).asObservable()
                .compactMap { result -> Mutation? in
                    if let (isWatchlist, objectID, isStared, watchedDate, isReviewed) = result {
                        return .setWatchlistStatus(isWatchlisted: isWatchlist, isStared: isStared, watchedDate: watchedDate, mediaObjectID: objectID, isReviewed: isReviewed)
                    } else {
                        return .setWatchlistStatus(isWatchlisted: false, isStared: false, watchedDate: nil, mediaObjectID: nil, isReviewed: false)
                    }
                }.catch { error in return .just(.showError(error)) }
            
            let detailFetchStream = mediaDBManager.fetchMediaEntity(id: media.id).asObservable()
                .flatMap { [weak self] entity -> Observable<Mutation> in
                    guard let self = self else { return .empty() }
                    if let entity = entity {
                        return .just(.getMediaDetail(entity.toMediaDetail()))
                    } else {
                        if !self.networkMonitor.isCurrentlyConnected { return .just(.showNetworkErrorAndDismiss) }
                        return self.fetchMediaCredits()
                    }
                }
            
            let essentialDataStream = Observable.merge(dbStatusStream, detailFetchStream)
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observe(on: mutationScheduler)
                .concat(Observable.just(.setEssentialDataLoaded(true)))

            let imageStream = Observable.merge(
                self.loadBackdropImage(currentState.media.backdropPath),
                self.loadPosterImage(currentState.media.posterPath)
            )
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .observe(on: mutationScheduler)

            let imageLoadingStream = imageStream
                .concat(Observable.just(.setImagesLoaded(true)))
            
            return Observable.merge(essentialDataStream, imageLoadingStream)
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
            guard currentState.processingAction == .none else { return .empty() }
            let media = currentState.media, casts = currentState.casts, creators = currentState.creators
            let isCurrentlyWatchlisted = currentState.isWatchlisted
            let actionStream: Observable<Mutation>
            
            if isCurrentlyWatchlisted {
                if let posterPath = media.posterPath { imageFileManager.deleteImage(urlString: posterPath) }
                if let backdropPath = media.backdropPath { imageFileManager.deleteImage(urlString: backdropPath) }
                
                actionStream = mediaDBManager.deleteMedia(id: media.id).asObservable()
                    .flatMap { _ -> Observable<Mutation> in
                            .just(.setWatchlistStatus(isWatchlisted: false, isStared: false, watchedDate: nil, mediaObjectID: nil, isReviewed: false))
                    }
                    .catch { error in
                        .just(.showError(DatabaseError.deleteFailed))
                    }
            } else {
                let posterSaveStream: Observable<Void>
                if let posterPath = media.posterPath, !posterPath.isEmpty {
                    posterSaveStream = imageProvider.fetchImage(urlString: posterPath)
                        .flatMap { [weak self] data -> Observable<Void> in
                            guard let self = self, let data = data else { return .just(()) }
                            self.imageFileManager.saveImage(image: data, urlString: posterPath)
                            return .just(())
                        }
                } else {
                    posterSaveStream = .just(())
                }
                
                let backdropSaveStream: Observable<Void>
                if let backdropPath = media.backdropPath, !backdropPath.isEmpty {
                    backdropSaveStream = imageProvider.fetchImage(urlString: backdropPath)
                        .flatMap { [weak self] data -> Observable<Void> in
                            guard let self = self, let data = data else { return .just(()) }
                            self.imageFileManager.saveImage(image: data, urlString: backdropPath)
                            return .just(())
                        }
                } else {
                    backdropSaveStream = .just(())
                }
                
                let createMediaStream = mediaDBManager.createMedia(id: media.id, title: media.title, overview: media.overview, type: media.mediaType.rawValue, posterURL: media.posterPath, backdropURL: media.backdropPath, genres: media.genreIDS, releaseDate: media.releaseDate, watchedDate: nil, creators: creators, casts: casts, addedDate: Date(), certificate: currentState.certificate, runtimeOrEpisodeInfo: currentState.runtimeOrEpisodeInfo)
                    .flatMap { _ in self.mediaDBManager.fetchMedia(id: media.id) }.asObservable()
                    .flatMap { result -> Observable<Mutation> in
                        if let (isWatchlist, objectID, isStared, watchedDate, isReviewed) = result {
                            return .just(.setWatchlistStatus(isWatchlisted: isWatchlist, isStared: isStared, watchedDate: watchedDate, mediaObjectID: objectID, isReviewed: isReviewed))
                        }
                        return .empty()
                    }
                actionStream = Observable.zip(posterSaveStream, backdropSaveStream).flatMap { _ in createMediaStream }.catch { error in
                        .just(.showError(DatabaseError.saveFailed))
                }
            }
            return .concat([.just(.setProcessingAction(.watchlist)), actionStream, .just(.setProcessingAction(.none))])
            
        case .watchedButtonTapped:
            return .just(.showSetWatchedDateAlert)
            
        case .writeReviewButtonTapped:
            let media = currentState.media
            let existingReview = reviewDBManager.fetchReview(id: media.id)
            return .just(.pushWriteReviewView(media, existingReview))
            
        case .updateWatchedDate(let date):
            guard currentState.processingAction == .none else { return .empty() }
            let media = currentState.media
            let updateStream = mediaDBManager.updateWatchedDate(id: media.id, watchedDate: date).asObservable()
                .flatMap { _ -> Observable<Mutation> in
                        .just(.setWatchedDate(date))
                }
                .catch { error in
                        .just(.showError(DatabaseError.updateFailed))
                }
            
            return .concat([.just(.setProcessingAction(.updateWatchedDate)), updateStream, .just(.setProcessingAction(.none))])
            
        case .moreOverviewButtonTapped:
            return .just(.toggleOverviewExpanded)
            
        case .setOverviewButtonVisible(let isTruncatable):
            return .just(.setOverviewTruncatable(isTruncatable))
            
        case .starButtonTapped:
            guard currentState.processingAction == .none else { return .empty() }
            let media = currentState.media
            let creators = currentState.creators
            let casts = currentState.casts
            let starToggle = !currentState.isStared
            
            let updateStream = mediaDBManager.updateIsStared(id: media.id, isStar: starToggle)
                .asObservable()
                .map { isStar -> Mutation in
                    .updateStarButton(isStar)
                }
            
            let createAndUpdateStream = updateStream.catch { [weak self] error -> Observable<Mutation> in
                guard let self = self else { return .just(.showError(DatabaseError.updateFailed)) }
                
                return self.mediaDBManager.createMedia(
                    id: media.id,
                    title: media.title,
                    overview: media.overview,
                    type: media.mediaType.rawValue,
                    posterURL: media.posterPath,
                    backdropURL: media.backdropPath,
                    genres: media.genreIDS,
                    releaseDate: media.releaseDate,
                    watchedDate: nil,
                    creators: creators,
                    casts: casts,
                    addedDate: nil,
                    certificate: self.currentState.certificate,
                    runtimeOrEpisodeInfo: self.currentState.runtimeOrEpisodeInfo
                )
                .asObservable()
                .flatMap { _ -> Observable<Mutation> in
                    return self.mediaDBManager.updateIsStared(id: media.id, isStar: starToggle)
                        .asObservable()
                        .map { isStar -> Mutation in
                            .updateStarButton(isStar)
                        }
                        .catch { _ -> Observable<Mutation> in
                            .just(.showError(DatabaseError.saveFailed))
                        }
                }
                .catch { _ -> Observable<Mutation> in
                    .just(.showError(DatabaseError.saveFailed))
                }
            }
            
            return Observable.concat([
                Observable.just(.setProcessingAction(.star)),
                createAndUpdateStream,
                Observable.just(.setProcessingAction(.none))
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setEssentialDataLoaded(let isLoaded):
            newState.isEssentialDataLoaded = isLoaded
        case .setImagesLoaded(let isLoaded):
            newState.areImagesLoaded = isLoaded
        case .getMediaDetail(let mediaInfo):
            let detail = mediaInfo
            newState.overview = detail.overview; newState.genres = detail.genres.joined(separator: " / ")
            newState.casts = detail.cast; newState.creators = detail.creator
            var sectionModels: [CreditsSectionModel] = []
            let creators = detail.creator.sorted(by: { $0.department ?? "" < $1.department ?? "" }).compactMap({ CreditsSectionItem.creators(item: $0) })
            if !creators.isEmpty { sectionModels.append(CreditsSectionModel.creators(item: creators)) }
            let casts = detail.cast.map({ CreditsSectionItem.casts(item: $0) })
            if !casts.isEmpty { sectionModels.append(CreditsSectionModel.casts(item: casts)) }
            newState.credits = sectionModels
            newState.releaseYear = detail.releaseYear; newState.certificate = detail.certificate
            newState.runtimeOrEpisodeInfo = detail.runtimeOrEpisodeInfo
        case .setBackdropImage(let image):
            newState.backDropImageData = image
        case .setPosterImage(let image):
            newState.posterImageData = image
        case .setWatchlistStatus(let isWatchlisted, let isStared, let date, let objectID, let isReviewed):
            newState.isWatchlisted = isWatchlisted; newState.watchedDate = date
            newState.mediaObjectID = objectID; newState.isStared = isStared; newState.isReviewed = isReviewed
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
        case .setProcessingAction(let action):
            newState.processingAction = action
        case .showNetworkErrorAndDismiss:
            newState.showNetworkErrorAndDismiss = ()
        case .showError(let error):
            newState.error = error
        }
        
        return newState
    }
    
    private func fetchMediaCredits() -> Observable<Mutation> {
        let targetType: TMDBTargetType
        let media = currentState.media
        
        switch media.mediaType {
        case .movie:
            targetType = TMDBTargetType.getMovieDetail(media.id)
            return networkService.callRequest(targetType).asObservable()
                .flatMap { (result: Result<MovieDetail, Error>) -> Observable<Mutation> in
                    switch result {
                    case .success(let detail): return .just(.getMediaDetail(detail.toDomain()))
                    case .failure(let error):
                        if let networkError = error as? NetworkError, networkError == .offline { return .just(.showNetworkErrorAndDismiss) }
                        else if let networkError = error as? NetworkError { return .just(.showError(networkError)) }
                        else { return .just(.showError(NetworkError.commonError)) }
                    }
                }
        case .tv:
            targetType = TMDBTargetType.getTVDetail(media.id)
            return networkService.callRequest(targetType).asObservable()
                .flatMap { (result: Result<TVDetail, Error>) -> Observable<Mutation> in
                    switch result {
                    case .success(let detail):
                        return .just(.getMediaDetail(detail.toDomain()))
                    case .failure(let error):
                        if let networkError = error as? NetworkError, networkError == .offline {
                            return .just(.showNetworkErrorAndDismiss)
                        }
                        else if let networkError = error as? NetworkError {
                            return .just(.showError(networkError))
                        }
                        else {
                            return .just(.showError(NetworkError.commonError))
                        }
                    }
                }
        default: return .empty()
        }
    }
    
    private func loadBackdropImage(_ imagePath: String?) -> Observable<Mutation> {
        guard let imagePath = imagePath, !imagePath.isEmpty else { return .just(.setBackdropImage(AppImage.emptyPosterImage)) }
        
        return imageProvider.fetchImage(urlString: imagePath)
            .map { data -> UIImage in
                guard let data = data, let image = UIImage(data: data) else {
                    return AppImage.emptyPosterImage
                }
                return image
            }
            .map { .setBackdropImage($0) }
            .catchAndReturn(.setBackdropImage(AppImage.emptyPosterImage))
    }
    
    private func loadPosterImage(_ imagePath: String?) -> Observable<Mutation> {
        guard let imagePath = imagePath, !imagePath.isEmpty else { return .just(.setPosterImage(AppImage.emptyPosterImage)) }
        
        return imageProvider.fetchImage(urlString: imagePath)
            .map { data -> UIImage in
                guard let data = data, let image = UIImage(data: data) else {
                    return AppImage.emptyPosterImage
                }
                return image
            }
            .map { .setPosterImage($0) }
            .catchAndReturn(.setPosterImage(AppImage.emptyPosterImage))
    }
}
