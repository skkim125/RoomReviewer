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
        var presentWriteReviewView: Void?
    }
    
    enum Action {
        case fetchData
        case writeButtonTapped
    }
    
    enum Mutation {
        case setLoading(Bool)
        case fetchedData([HomeSectionItem])
        case presentWriteReviewView
        case showError(Error)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .fetchData:
            return Observable.concat([
                .just(.setLoading(true)),
                networkService.callRequest(TMDBTargetType.tv)
                    .asObservable()
                    .flatMap { (result: Result<TVList, Error>) -> Observable<Mutation> in
                        switch result {
                        case .success(let success):
                            let datas = success.results.map { HomeSectionItem.tv(item: $0) }
                            return .just(.fetchedData(datas))
                        case .failure(let error):
                            return .just(.showError(error))
                        }
                    },
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
        case .fetchedData(let tvs):
            let result = HomeSectionModel.tv(item: tvs)
            newState.medias = [result]
        case .setLoading(let loaded):
            newState.isLoading = loaded
        case .presentWriteReviewView:
            newState.presentWriteReviewView = ()
        }
        
        return newState
    }
}
