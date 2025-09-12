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
    
    init(media: Media, networkService: NetworkService, imageProvider: ImageProviding, imageFileManager: ImageFileManaging, mediaDBManager: MediaDBManager, reviewDBManager: ReviewDBManager) {
        self.initialState = State(media: media, title: media.title)
        self.networkService = networkService
        self.imageProvider = imageProvider
        self.imageFileManager = imageFileManager
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
        var releaseYear: String?
        var certificate: String?
        var runtimeOrEpisodeInfo: String?
        var isOverviewButtonVisible: Bool = false
        var isOverviewExpanded: Bool = false
        var isLoading: Bool?
        var errorType: Error?
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
        case setWatchlistStatus(isWatchlisted: Bool, isStared: Bool, watchedDate: Date?, mediaObjectID: NSManagedObjectID?, isReviewed: Bool)
        case showSetWatchedDateAlert
        case setWatchedDate(Date)
        case pushWriteReviewView(Media, ReviewEntity?)
        case toggleOverviewExpanded
        case setOverviewTruncatable(Bool)
        case updateStarButton(Bool)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            let media = currentState.media
            
            let initialDataStream = Observable.just(Mutation.setInitialData(
                overview: media.overview,
                genres: API.convertGenreString(media.genreIDS).joined(separator: " / ")
            ))
            
            let localDataStream = mediaDBManager.fetchMediaEntity(id: media.id)
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .asObservable()
                .flatMap { entity -> Observable<Mutation> in
                    if let entity = entity {
                        let mediaDetail = entity.toMediaDetail()
                        return .just(.getMediaDetail(mediaDetail))
                    } else {
                        return self.fetchMediaCredits()
                    }
                }
            
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
            
            let imageStream = Observable.merge(
                self.loadBackdropImage(currentState.media.backdropPath)
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated)),
                self.loadPosterImage(currentState.media.posterPath)
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            )
            
            return Observable.concat([
                .just(.setLoading(true)),
                Observable.merge(initialDataStream, localDataStream, dbStatusStream, imageStream)
                    .observe(on: MainScheduler.instance),
                .just(.setLoading(false))
            ])
            
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
                    .catch { .just(.showError($0)) }
                
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
                    .catch { .just(.showError($0)) }
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
                    return mediaDBManager.createMedia(id: media.id, title: media.title, overview: media.overview, type: media.mediaType.rawValue, posterURL: media.posterPath, backdropURL: media.backdropPath, genres: media.genreIDS, releaseDate: media.releaseDate, watchedDate: nil, creators: creators, casts: casts, addedDate: nil, certificate: self.currentState.certificate, runtimeOrEpisodeInfo: self.currentState.runtimeOrEpisodeInfo)
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
            
            newState.releaseYear = detail.releaseYear
            newState.certificate = detail.certificate
            newState.runtimeOrEpisodeInfo = detail.runtimeOrEpisodeInfo
            
        case .setBackdropImage(let image):
            newState.backDropImageData = image
            
        case .setPosterImage(let image):
            newState.posterImageData = image
            
        case .showError(let error):
            newState.errorType = error
            
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
