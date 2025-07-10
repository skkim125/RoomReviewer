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
    
    init(networkService: NetworkService) {
        initialState = State()
        self.networkService = networkService
    }
    
    struct State {
        var isLoading: Bool = false
        var medias: [HomeSectionModel] = []
        var errorType: Error?
        @Pulse var presentWriteReviewView: Void?
    }
    
    enum Action {
        case fetchData
        case writeButtonTapped
    }
    
    enum Mutation {
        case setLoading(Bool)
        case fetchedData([HomeSectionModel])
        case presentWriteReviewView
        case showError(Error)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetchData:
            return Observable.concat([
                .just(.setLoading(true)),
                fetchMedias(),
                .just(.setLoading(false))
            ])
        case .writeButtonTapped:
            return .just(.presentWriteReviewView)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .showError(let error):
            newState.errorType = error
        case .fetchedData(let sections):
            newState.medias = sections
        case .setLoading(let loaded):
            newState.isLoading = loaded
        case .presentWriteReviewView:
            newState.presentWriteReviewView = ()
        }
        
        return newState
    }
}

extension HomeReactor {
    private func fetchMedias() -> Observable<Mutation> {
        let tvRequest = networkService.callRequest(TMDBTargetType.tv)
            .asObservable()
            .map { (result: Result<TVList, Error>) -> [HomeSectionItem] in
                switch result {
                case .success(let success):
                    return success.results.map { HomeSectionItem.tv(item: $0) }
                case .failure:
                    return []
                }
            }
        
        let movieRequest = networkService.callRequest(TMDBTargetType.movie)
            .asObservable()
            .map { (result: Result<MovieList, Error>) -> [HomeSectionItem] in
                switch result {
                case .success(let success):
                    return success.results.map { HomeSectionItem.movie(item: $0) }
                case .failure:
                    return []
                }
            }
        
        return Observable.zip(movieRequest, tvRequest)
            .map { (movies, tvs) -> Mutation in
                var sections: [HomeSectionModel] = []
                sections.append(HomeSectionModel.movie(item: movies))
                sections.append(HomeSectionModel.tv(item: tvs))
                
                return .fetchedData(sections)
            }
            .catch { error in
                return .just(.showError(error))
            }
    }
}
