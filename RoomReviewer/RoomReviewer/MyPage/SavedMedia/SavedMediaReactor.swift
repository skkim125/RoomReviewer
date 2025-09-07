//
//  SavedMediaReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/5/25.
//

import Foundation
import ReactorKit
import RxSwift

enum SectionType {
    case watchlist
    case watched
    case reviewed
    case isStared
    
    var navigationbarTitle: String {
        switch self {
        case .watchlist:
            return "보고 싶어요"
        case .watched:
            return "내가 본 컨텐츠"
        case .reviewed:
            return "평론한 컨텐츠"
        case .isStared:
            return "즐겨찾기"
        }
    }
}

final class SavedMediaReactor: Reactor {
    struct State {
        var sectionType: SectionType
        var savedMedia: [Media] = []
        var navigationbarTitle: String? {
            return sectionType.navigationbarTitle
        }
        @Pulse var selectedMedia: Media?
        @Pulse var dismissAction: Void?
        @Pulse var updateSavedMedias: Void?
    }
    
    enum Action {
        case viewDidLoad
        case dismissSavedMediaView
        case selectedMedia(Media)
        case updateSavedMedias
    }
    
    enum Mutation {
        case setSavedMedias([Media])
        case moveMediaDetail(Media)
        case dismissSavedMediaView
        case updateSavedMedias
    }
    
    let initialState: State
    
    private let mediaDBManager: MediaDBManager
    
    init(_ sectionType: SectionType, mediaDBManager: MediaDBManager) {
        self.initialState = State(sectionType: sectionType)
        self.mediaDBManager = mediaDBManager
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .dismissSavedMediaView:
            return .just(.dismissSavedMediaView)
        case .viewDidLoad:
            return getSavedMedia()
            
        case .selectedMedia(let media):
            return .just(.moveMediaDetail(media))
            
        case .updateSavedMedias:
            return .concat(getSavedMedia(), .just(.updateSavedMedias))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setSavedMedias(let medias):
            newState.savedMedia = medias
        case .moveMediaDetail(let media):
            newState.selectedMedia = media
        case .dismissSavedMediaView:
            newState.dismissAction = ()
            
        case .updateSavedMedias:
            newState.updateSavedMedias = ()
        }
        
        return newState
    }
    
    private func getSavedMedia() -> Observable<Mutation> {
        let savedMedia = mediaDBManager.fetchAllMedia()
            .asObservable()
            .map { [weak self] mediaEntities -> [Media] in
                guard let self = self else { return [] }
                let sectionType = currentState.sectionType
                var medias: [MediaEntity] = []
                switch sectionType {
                case .watchlist:
                    medias = mediaEntities.filter { $0.watchedDate == nil }
                case .watched:
                    medias = mediaEntities.filter { $0.watchedDate != nil && $0.review == nil }
                case .reviewed:
                    medias = mediaEntities.filter { $0.review != nil }
                case .isStared:
                    medias = mediaEntities.filter { $0.isStar }
                }
                
                return medias.map { $0.toDomain() }
            }
        
        return savedMedia.map { .setSavedMedias($0) }
    }
}
