//
//  HomeReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/13/25.
//

import Foundation
import RxSwift
import RxDataSources
import ReactorKit

final class HomeReactor: Reactor {
    var initialState: State
    private let networkService: NetworkService
    private let mediaDBManager: MediaDBManager
    private let networkMonitor: NetworkMonitoring
    private var disposeBag = DisposeBag()
    
    init(networkService: NetworkService, mediaDBManager: MediaDBManager, networkMonitor: NetworkMonitoring) {
        self.initialState = State()
        self.networkService = networkService
        self.mediaDBManager = mediaDBManager
        self.networkMonitor = networkMonitor
    }
    
    struct State {
        var sections: [HomeSectionModel] = []
        var isLoading: Bool = true
        var isOffline: Bool = false
        @Pulse var presentWriteReviewView: Void?
        @Pulse var selectedMedia: Media?
    }
    
    enum Action {
        case fetchData
        case writeButtonTapped
        case mediaSelected(Media)
        case updateWatchlist
    }
    
    enum Mutation {
        case setSections([HomeSectionModel])
        case setLoading(Bool)
        case setOffline(Bool)
        case presentWriteReviewView
        case presentMediaDetail(Media)
        case updateWatchlist([HomeSectionItem])
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetchData:
            let isConnected = networkMonitor.isCurrentlyConnected
            let dataStream = isConnected ? fetchOnlineData() : fetchOfflineData()
            
            return Observable.concat([
                .just(.setLoading(true)),
                .just(.setOffline(!isConnected)),
                dataStream,
                .just(.setLoading(false))
            ])

        case .writeButtonTapped:
            return .just(.presentWriteReviewView)
            
        case .mediaSelected(let media):
            return .just(.presentMediaDetail(media))
            
        case .updateWatchlist:
            return updateWatchlist()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setSections(let sections):
            newState.sections = sections
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setOffline(let isOffline):
            newState.isOffline = isOffline
        case .presentWriteReviewView:
            newState.presentWriteReviewView = ()
        case .presentMediaDetail(let media):
            newState.selectedMedia = media
        case .updateWatchlist(let items):
            var currentSections = newState.sections
            if let index = currentSections.firstIndex(where: { if case .watchlist = $0 { return true }
                return false
            }) {
                if !items.isEmpty {
                    currentSections[index] = HomeSectionModel.watchlist(item: items)
                } else {
                    currentSections.remove(at: index)
                }
            } else if !items.isEmpty {
                let newWatchlistSection = HomeSectionModel.watchlist(item: items)
                if currentSections.count > 1 {
                    currentSections.insert(newWatchlistSection, at: 1)
                } else {
                    currentSections.append(newWatchlistSection)
                }
            }
            newState.sections = currentSections
        }
        
        return newState
    }
    
    private func fetchOnlineData() -> Observable<Mutation> {
        let trendingMedias = fetchTrending()
        let watchlist = fetchWatchlist()
        let movies = fetchMovie()
        let tvs = fetchTV()
        
        return Observable.zip(trendingMedias, watchlist, movies, tvs)
            .map { (trend, watchlists, movies, tvs) -> Mutation in
                var sections: [HomeSectionModel] = []
                
                if !trend.isEmpty {
                    sections.append(HomeSectionModel.trend(item: trend))
                }
                if !watchlists.isEmpty {
                    sections.append(HomeSectionModel.watchlist(item: watchlists))
                }
                if !movies.isEmpty {
                    sections.append(HomeSectionModel.movie(item: movies))
                }
                if !tvs.isEmpty {
                    sections.append(HomeSectionModel.tv(item: tvs))
                }
                
                return .setSections(sections)
            }
    }
    
    private func fetchOfflineData() -> Observable<Mutation> {
        return fetchWatchlist()
            .map { watchlists -> Mutation in
                var sections: [HomeSectionModel] = []
                if !watchlists.isEmpty {
                    sections.append(HomeSectionModel.watchlist(item: watchlists))
                }
                return .setSections(sections)
            }
    }
    
    private func updateWatchlist() -> Observable<Mutation> {
        return mediaDBManager.fetchAllMedia()
            .asObservable()
            .map { medias -> [HomeSectionItem] in
                return medias.filter { $0.review == nil && $0.addedDate != nil }
                    .map { $0.toDomain() }
                    .map { HomeSectionItem.watchlist(item: $0) }
            }
            .map { .updateWatchlist($0) }
    }
    
    private func fetchTrending() -> Observable<[HomeSectionItem]> {
        let trendingRequest = networkService.callRequest(TMDBTargetType.trend)
            .asObservable()
            .map { (result: Result<TrendResultResponse, Error>) -> [HomeSectionItem] in
                switch result {
                case .success(let success):
                    let result = success.results.map {
                        let mediaType = MediaType(rawValue: $0.mediaType.rawValue) ?? .person
                        let title = mediaType == .movie ? $0.title ?? "" : $0.name ?? ""
                        let releaseDate = mediaType == .movie ? $0.releaseDate : $0.firstAirDate
                        
                        return HomeSectionItem.trend(item: Media(id: $0.id, mediaType: mediaType, title: title, overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, genreIDS: $0.genreIDS, releaseDate: releaseDate, watchedDate: nil))
                    }
                    
                    return result
                    
                case .failure:
                    return []
                }
            }
        
        return trendingRequest
    }
    
    private func fetchWatchlist() -> Observable<[HomeSectionItem]> {
        let watchlistRequest = mediaDBManager.fetchAllMedia()
            .asObservable()
            .map { medias -> [HomeSectionItem] in
                let result = medias.filter {
                    $0.review == nil
                }.map {
                    return $0.toDomain()
                }.map {
                    HomeSectionItem.watchlist(item: $0)
                }
                
                return result
            }
        
        return watchlistRequest
    }
    
    private func fetchMovie() -> Observable<[HomeSectionItem]> {
        let movieRequest = networkService.callRequest(TMDBTargetType.movie)
            .asObservable()
            .map { (result: Result<MovieList, Error>) -> [HomeSectionItem] in
                switch result {
                case .success(let success):
                    let prefixed = success.results.prefix(10)
                    
                    return prefixed.map { HomeSectionItem.movie(item: Media(id: $0.id, mediaType: .movie, title: $0.title, overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, genreIDS: $0.genreIDS, releaseDate: $0.releaseDate, watchedDate: nil)) }
                case .failure:
                    return []
                }
            }
        
        return movieRequest
    }
    
    private func fetchTV() -> Observable<[HomeSectionItem]> {
        let tvRequest = networkService.callRequest(TMDBTargetType.tv)
            .asObservable()
            .map { (result: Result<TVList, Error>) -> [HomeSectionItem] in
                switch result {
                case .success(let success):
                    let prefixed = success.results.prefix(10)
                    
                    return prefixed.map { HomeSectionItem.tv(item: Media(id: $0.id, mediaType: .tv, title: $0.name, overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, genreIDS: $0.genreIDS, releaseDate: $0.firstAirDate, watchedDate: nil)) }
                case .failure:
                    return []
                }
            }
        
        return tvRequest
    }
}
