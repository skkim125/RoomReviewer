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
        @Pulse var selectedMedia: Media?
    }
    
    enum Action {
        case fetchData
        case writeButtonTapped
        case mediaSelected(Media)
    }
    
    enum Mutation {
        case setLoading(Bool)
        case fetchedData([HomeSectionModel])
        case presentWriteReviewView
        case presentMediaDetail(Media)
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
        case .mediaSelected(let media):
            return .just(.presentMediaDetail(media))
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
        case .presentMediaDetail(let media):
            newState.selectedMedia = media
        }
        
        return newState
    }
}

extension HomeReactor {
    private func fetchMedias() -> Observable<Mutation> {
        let movieRequest = networkService.callRequest(TMDBTargetType.movie)
            .asObservable()
            .map { (result: Result<MovieList, Error>) -> [HomeSectionItem] in
                switch result {
                case .success(let success):
                    let prefixed = success.results.prefix(10)
                    
                    return prefixed.map { HomeSectionItem.movie(item: Media(id: $0.id, mediaType: .movie, title: $0.title, overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, genreIDS: $0.genreIDS, releaseDate: $0.releaseDate)) }
                case .failure:
                    return []
                }
            }
        
        
        let tvRequest = networkService.callRequest(TMDBTargetType.tv)
            .asObservable()
            .map { (result: Result<TVList, Error>) -> [HomeSectionItem] in
                switch result {
                case .success(let success):
                    let prefixed = success.results.prefix(10)
                    
                    return prefixed.map { HomeSectionItem.tv(item: Media(id: $0.id, mediaType: .tv, title: $0.name, overview: $0.overview, posterPath: $0.posterPath, backdropPath: $0.backdropPath, genreIDS: $0.genreIDS, releaseDate: $0.firstAirDate)) }
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
