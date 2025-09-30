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
        print("mediaName: \(media.title), id: \(media.id)")
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
        var videos: [Video] = []
        var mediaDetailSectionModels: [MediaDetailSectionModel] = []
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
        var videoSelected: Video?

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
        @Pulse var showMoveYoutubeAlert: Video?
        @Pulse var showUpdateCompleteAlert: Void?
        @Pulse var pushCreditsListView: [Cast]?
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
        case videoSelected(Video?)
        case seeMoreCreditsButtonTapped
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
        case showMoveYoutubeAlert(Video)
        case showUpdateCompleteAlert
        case pushCreditsListView(credits: [Cast])
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
                    
                    let localDataStream: Observable<Mutation>
                    if let entity = entity {
                        localDataStream = .just(.getMediaDetail(entity.toMediaDetail()))
                    } else {
                        localDataStream = .empty()
                    }
                    
                    let networkDataStream: Observable<Mutation>
                    
                    if self.networkMonitor.isCurrentlyConnected {
                        networkDataStream = self.fetchMediaCredits()
                            .flatMap { mutation -> Observable<Mutation> in
                                if case .getMediaDetail(let detail) = mutation {
                                    return self.mediaDBManager.updateMediaDetail(id: media.id, mediaDetail: detail)
                                        .asObservable()
                                        .flatMap { wasUpdated -> Observable<Mutation> in
                                            if wasUpdated {
                                                return .concat(.just(mutation), .just(.showUpdateCompleteAlert))
                                            } else {
                                                return .just(mutation)
                                            }
                                        }
                                        .catchAndReturn(mutation)
                                }
                                return .just(mutation)
                            }
                    } else {
                        networkDataStream = .empty()
                    }
                    
                    if entity == nil && !self.networkMonitor.isCurrentlyConnected {
                        return .just(.showNetworkErrorAndDismiss)
                    }
                    
                    return Observable.concat(localDataStream, networkDataStream)
                }
            
            let essentialDataStream = Observable.merge(dbStatusStream, detailFetchStream)
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observe(on: mutationScheduler)
                .concat(Observable.just(.setEssentialDataLoaded(true)))
            
            let imageStream = Observable.merge(loadBackdropImage(currentState.media.backdropPath), loadPosterImage(currentState.media.posterPath))
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observe(on: mutationScheduler)
                .concat(Observable.just(.setImagesLoaded(true)))
            
            return Observable.merge(essentialDataStream, imageStream)
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
            let media = currentState.media, casts = currentState.casts, creators = currentState.creators, videos = currentState.videos
            let isCurrentlyWatchlisted = currentState.isWatchlisted
            let actionStream: Observable<Mutation>
            
            if isCurrentlyWatchlisted {
                if let posterPath = media.posterPath {
                    let posterURL = API.tmdbImageURL + posterPath
                    imageFileManager.deleteImage(urlString: posterURL)
                }
                if let backdropPath = media.backdropPath {
                    let backdropURL = API.tmdbImageURL + backdropPath
                    imageFileManager.deleteImage(urlString: backdropURL)
                }
                
                let videoPaths = videos.map { API.youtubeThumnailURL + $0.key }
                for videoPath in videoPaths {
                    imageFileManager.deleteImage(urlString: videoPath)
                }
                
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
                    let endpoint = ImageEndpoint(type: .tmdbImage(path: posterPath))
                    posterSaveStream = imageProvider.fetchImage(endpoint: endpoint).map { _ in () }
                } else {
                    posterSaveStream = .just(())
                }
                
                let backdropSaveStream: Observable<Void>
                if let backdropPath = media.backdropPath, !backdropPath.isEmpty {
                    let endpoint = ImageEndpoint(type: .tmdbImage(path: backdropPath))
                    backdropSaveStream = imageProvider.fetchImage(endpoint: endpoint).map { _ in () }
                } else {
                    backdropSaveStream = .just(())
                }
                
                let videoThumnailSaveStream: Observable<Void>
                if !videos.isEmpty {
                    let endpoints = videos.compactMap { video -> ImageEndpoint? in
                        guard !video.key.isEmpty else { return nil }
                        return ImageEndpoint(type: .youtubeThumbnail(key: video.key))
                    }
                    
                    let fetchStreams = endpoints.map { imageProvider.fetchImage(endpoint: $0) }
                    videoThumnailSaveStream = Observable.zip(fetchStreams).map { _ in () }
                    
                } else {
                    videoThumnailSaveStream = .just(())
                }
                
                let createMediaStream = mediaDBManager.createMedia(id: media.id, title: media.title, overview: media.overview, type: media.mediaType.rawValue, posterURL: media.posterPath, backdropURL: media.backdropPath, genres: media.genreIDS, releaseDate: media.releaseDate, watchedDate: nil, creators: creators, casts: casts, videos: videos, addedDate: Date(), certificate: currentState.certificate, runtimeOrEpisodeInfo: currentState.runtimeOrEpisodeInfo)
                    .flatMap { _ in self.mediaDBManager.fetchMedia(id: media.id) }.asObservable()
                    .flatMap { result -> Observable<Mutation> in
                        if let (isWatchlist, objectID, isStared, watchedDate, isReviewed) = result {
                            return .just(.setWatchlistStatus(isWatchlisted: isWatchlist, isStared: isStared, watchedDate: watchedDate, mediaObjectID: objectID, isReviewed: isReviewed))
                        }
                        return .empty()
                    }
                actionStream = Observable.zip(posterSaveStream, backdropSaveStream, videoThumnailSaveStream).flatMap { _ in createMediaStream }.catch { error in
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
            let videos = currentState.videos
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
                    videos: videos,
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
            
        case .videoSelected(let video):
            guard let video = video else { return .empty() }
            return .just(.showMoveYoutubeAlert(video))
            
        case .seeMoreCreditsButtonTapped:
            let casts = currentState.casts
            return .just(.pushCreditsListView(credits: casts))
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
            
            newState.overview = detail.overview
            newState.genres = detail.genres.joined(separator: " / ")
            newState.casts = detail.cast
            newState.creators = detail.creator
            
            var sectionModels: [MediaDetailSectionModel] = []
            
            let creators = detail.creator.prefix(10).sorted(by: { $0.department ?? "" < $1.department ?? "" }).compactMap({ MediaDetailSectionItem.creator(item: $0) })
            if !creators.isEmpty {
                sectionModels.append(MediaDetailSectionModel.creators(items: creators))
            }
            
            var castItems: [MediaDetailSectionItem] = []
            let allCasts = detail.cast
            
            if allCasts.count > 10 {
                let top10Casts = allCasts.prefix(10)
                castItems.append(contentsOf: top10Casts.map { .cast(item: $0) })
            } else {
                castItems.append(contentsOf: allCasts.map { .cast(item: $0) })
            }
            
            if !castItems.isEmpty {
                sectionModels.append(MediaDetailSectionModel.casts(items: castItems))
            }
            
            if detail.cast.count > 10 {
                sectionModels.append(MediaDetailSectionModel.seeMore(items: [.seeMore]))
            }
            
            if let videos = detail.video {
                let convertVideoSectionItems = videos.map { MediaDetailSectionItem.video(item: $0) }
                if !convertVideoSectionItems.isEmpty {
                    sectionModels.append(MediaDetailSectionModel.videos(items: convertVideoSectionItems))
                    newState.videos = videos
                }
            }
            
            newState.mediaDetailSectionModels = sectionModels
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
        case .setProcessingAction(let action):
            newState.processingAction = action
        case .showNetworkErrorAndDismiss:
            newState.showNetworkErrorAndDismiss = ()
        case .showError(let error):
            newState.error = error
        case .showUpdateCompleteAlert:
            newState.showUpdateCompleteAlert = ()
        case .showMoveYoutubeAlert(let video):
            newState.showMoveYoutubeAlert = video
        case .pushCreditsListView(let credits):
            newState.pushCreditsListView = credits
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
        default:
            return .empty()
        }
    }
    
    private func loadBackdropImage(_ imagePath: String?) -> Observable<Mutation> {
        guard let imagePath = imagePath, !imagePath.isEmpty else { return .just(.setBackdropImage(AppImage.emptyPosterImage)) }
        
        let backdropEndpoint = ImageEndpoint(type: .tmdbImage(path: imagePath))
        return imageProvider.fetchImage(endpoint: backdropEndpoint)
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
        
        let posterEndpoint = ImageEndpoint(type: .tmdbImage(path: imagePath))
        return imageProvider.fetchImage(endpoint: posterEndpoint)
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
