//
//  WriteReviewReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/6/25.
//

import Foundation
import RxSwift
import RxDataSources
import ReactorKit

final class SearchMediaReactor: Reactor {
    var initialState: State
    private let networkService: NetworkService
    
    init(networkService: NetworkService) {
        initialState = State()
        self.networkService = networkService
    }
    
    struct State {
        var query: String?
        var isLoading: Bool = false
        var isLoadingNextPage: Bool = false
        var currentPage: Int = 1
        var totalPages: Int = 1
        var searchResults: [Media] = []
        @Pulse var errorType: Error?
        @Pulse var dismissAction: Void?
        @Pulse var selectedMedia: Media?
        @Pulse var isLastPage: Void?
        var hasShownLastPageAlert: Bool = false
    }
    
    enum Action {
        case updateQuery(String?)
        case searchButtonTapped
        case loadNextPage
        case dismissWriteReview
        case selectedMedia(Media)
        case scrolledToBottom
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setLoadingNextPage(Bool)
        case setQuery(String?)
        case setResults([Media], totalPages: Int)
        case appendResults([Media], totalPages: Int)
        case resetPages
        case showError(Error)
        case dismissWriteReview
        case pushDetailView(Media)
        case notifyLastPage
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateQuery(let query):
            return .just(.setQuery(query))
            
        case .searchButtonTapped:
            guard let searchText = currentState.query?.trimmingCharacters(in: .whitespacesAndNewlines), !searchText.isEmpty else {
                return .empty()
            }
            
            let searchStream = networkService.callRequest(TMDBTargetType.searchMulti(searchText, 1))
                .asObservable()
                .flatMap { (result: Result<SearchResult, Error>) -> Observable<Mutation> in
                    switch result {
                    case .success(let success):
                        let datas = success.results.filter { $0.mediaType != .person }.filter {
                            if let genres = $0.genreIDS, !genres.isEmpty {
                                return !(genres.contains(10764))
                            } else {
                                return false
                            }
                        }.map {
                            Media(id: $0.id, mediaType: $0.mediaType == .movie ? .movie : .tv, title: ($0.title ?? $0.name) ?? "", overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, genreIDS: $0.genreIDS ?? [], releaseDate: $0.mediaType == .movie ? $0.releaseDate : $0.firstAirDate, watchedDate: nil)
                        }
                        return .just(.setResults(datas, totalPages: success.totalPages))
                    case .failure(let error):
                        print(error.localizedDescription)
                        return .just(.showError(error))
                    }
                }
            
            return Observable.concat([
                .just(.setLoading(true)),
                .just(.resetPages),
                searchStream,
                .just(.setLoading(false))
            ])
            
        case .loadNextPage:
            guard !currentState.isLoading, !currentState.isLoadingNextPage, currentState.currentPage < currentState.totalPages else {
                return .empty()
            }
            
            guard let searchText = currentState.query?.trimmingCharacters(in: .whitespacesAndNewlines), !searchText.isEmpty else {
                return .empty()
            }
            
            let nextPage = currentState.currentPage + 1
            
            let searchStream = networkService.callRequest(TMDBTargetType.searchMulti(searchText, nextPage))
                .asObservable()
                .flatMap { (result: Result<SearchResult, Error>) -> Observable<Mutation> in
                    switch result {
                    case .success(let success):
                        let datas = success.results.filter { $0.mediaType != .person }.filter {
                            if let genres = $0.genreIDS, !genres.isEmpty {
                                return !(genres.contains(10764))
                            } else {
                                return false
                            }
                        }.map {
                            Media(id: $0.id, mediaType: $0.mediaType == .movie ? .movie : .tv, title: ($0.title ?? $0.name) ?? "", overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, genreIDS: $0.genreIDS ?? [], releaseDate: $0.mediaType == .movie ? $0.releaseDate : $0.firstAirDate, watchedDate: nil)
                        }
                        return .just(.appendResults(datas, totalPages: success.totalPages))
                    case .failure(let error):
                        print(error.localizedDescription)
                        return .just(.showError(error))
                    }
                }
            
            return Observable.concat([
                .just(.setLoadingNextPage(true)),
                searchStream,
                .just(.setLoadingNextPage(false))
            ])
            
        case .dismissWriteReview:
            return .just(.dismissWriteReview)
        case .selectedMedia(let media):
            return .just(.pushDetailView(media))
        case .scrolledToBottom:
            if currentState.currentPage == currentState.totalPages, !currentState.hasShownLastPageAlert {
                return .just(.notifyLastPage)
            }
            return .empty()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setQuery(let query):
            newState.query = query
            
        case .showError(let error):
            newState.errorType = error
            
        case .setResults(let medias, let totalPages):
            newState.searchResults = medias
            newState.totalPages = totalPages
            newState.currentPage = 1
            newState.hasShownLastPageAlert = false
            
        case .appendResults(let medias, let totalPages):
            newState.searchResults.append(contentsOf: medias)
            newState.totalPages = totalPages
            newState.currentPage += 1
            
        case .resetPages:
            newState.currentPage = 1
            newState.totalPages = 1
            newState.searchResults = []
            newState.hasShownLastPageAlert = false
            
        case .setLoading(let loaded):
            newState.isLoading = loaded
            
        case .setLoadingNextPage(let isLoading):
            newState.isLoadingNextPage = isLoading
            
        case .dismissWriteReview:
            newState.dismissAction = ()
            
        case .pushDetailView(let media):
            newState.selectedMedia = media
            
        case .notifyLastPage:
            newState.isLastPage = ()
            newState.hasShownLastPageAlert = true
        }
        print(newState.currentPage)
        return newState
    }
}
