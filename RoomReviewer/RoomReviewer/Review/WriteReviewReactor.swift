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

final class WriteReviewReactor: Reactor {
    var initialState: State
    private let networkService: NetworkService
    
    init(networkService: NetworkService) {
        initialState = State()
        self.networkService = networkService
    }
    
    struct State {
        var query: String?
        var isLoading: Bool = false
        @Pulse var medias: [Search]?
        var errorType: Error?
        @Pulse var dismissAction: Void?
    }
    
    enum Action {
        case updateQuery(String?)
        case searchButtonTapped
        case dismissWriteReview
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setQuery(String?)
        case searchSuccessed([Search])
        case showError(Error)
        case dismissWriteReview
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
                            let datas = success.results
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
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setQuery(let query):
            newState.query = query
            
        case .showError(let error):
            newState.errorType = error
            
        case .searchSuccessed(let tvs):
            newState.medias = tvs
            
        case .setLoading(let loaded):
            newState.isLoading = loaded
            
        case .dismissWriteReview:
            newState.dismissAction = ()
        }
        
        return newState
    }
}
