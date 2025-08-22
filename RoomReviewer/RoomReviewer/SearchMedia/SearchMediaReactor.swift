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
        @Pulse var searchResults: [Media]?
        @Pulse var errorType: Error?
        @Pulse var dismissAction: Void?
        @Pulse var selectedMedia: Media?
    }
    
    enum Action {
        case updateQuery(String?)
        case searchButtonTapped
        case dismissWriteReview
        case selectedMedia(Media)
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setQuery(String?)
        case searchSuccessed([Media])
        case showError(Error)
        case dismissWriteReview
        case pushDetailView(Media)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateQuery(let query):
            return .just(.setQuery(query))
            
        case .searchButtonTapped:
            guard let searchText = currentState.query?.trimmingCharacters(in: .whitespacesAndNewlines), !searchText.isEmpty else {
                return .empty()
            }
            
            return Observable.concat([
                .just(.setLoading(true)),
                networkService.callRequest(TMDBTargetType.searchMulti(searchText, 1))
                    .asObservable()
                    .flatMap { (result: Result<SearchResult, Error>) -> Observable<Mutation> in
                        switch result {
                        case .success(let success):
                            let datas = success.results.filter { $0.mediaType != .person }.map {
                                Media(id: $0.id, mediaType: $0.mediaType == .movie ? .movie : .tv, title: ($0.title ?? $0.name) ?? "", overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, genreIDS: $0.genreIDS ?? [], releaseDate: $0.mediaType == .movie ? $0.releaseDate : $0.firstAirDate, watchedDate: nil)
                            }
                            return .just(.searchSuccessed(datas))
                        case .failure(let error):
                            print(error.localizedDescription)
                            return .just(.showError(error))
                        }
                    },
                .just(.setLoading(false))
            ])
        case .dismissWriteReview:
            return .just(.dismissWriteReview)
        case .selectedMedia(let media):
            return .just(.pushDetailView(media))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setQuery(let query):
            newState.query = query
            
        case .showError(let error):
            newState.errorType = error
            
        case .searchSuccessed(let medias):
            newState.searchResults = medias
            
        case .setLoading(let loaded):
            newState.isLoading = loaded
            
        case .dismissWriteReview:
            newState.dismissAction = ()
            
        case .pushDetailView(let media):
            newState.selectedMedia = media
        }
        
        return newState
    }
}
