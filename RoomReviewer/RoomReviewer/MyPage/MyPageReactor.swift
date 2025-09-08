//
//  MyPageReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/5/25.
//

import Foundation
import ReactorKit
import RxSwift

final class MyPageReactor: Reactor {
    
    enum Action {
        case viewDidLoad
        case itemSelected(IndexPath)
        case updateSections
    }
    
    enum Mutation {
        case setSections([MyPageSectionModel])
        case moveMyPageSection(MyPageSectionItem?)
        case updateSections
    }
    
    struct State {
        var sections: [MyPageSectionModel] = []
        @Pulse var selectedMyPageSection: MyPageSectionItem?
        @Pulse var updateSection: Void?
    }
    
    private let mediaDBManager: MediaDBManager
    let initialState: State
    
    init(mediaDBManager: MediaDBManager) {
        self.initialState = State()
        self.mediaDBManager = mediaDBManager
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return getSavedMediaCount()
            
        case .itemSelected(let indexPath):
            let selectedItem = currentState.sections[indexPath.section].items[indexPath.row]
            return .just(.moveMyPageSection(selectedItem))
            
        case .updateSections:
            return .concat(getSavedMediaCount(), .just(.updateSections))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setSections(let sections):
            newState.sections = sections
        case .moveMyPageSection(let item):
            newState.selectedMyPageSection = item
        case .updateSections:
            newState.updateSection = ()
        }
        
        return newState
    }
    
    private func getSavedMediaCount() -> Observable<Mutation> {
        let sectionModel = mediaDBManager.fetchAllMedia()
            .asObservable()
            .map { mediaEntities -> [MyPageSectionModel] in
                let watchlistCount = mediaEntities.filter { $0.addedDate != nil }.count
                let watchHistoryCount = mediaEntities.filter { $0.watchedDate != nil }.count
                let reviewCount = mediaEntities.filter { $0.review != nil }.count
                let isStarCount = mediaEntities.filter { $0.isStar }.count
                
                let activitySectionModel: MyPageSectionModel = .myActivity(items: [.watchlist(count: watchlistCount), .watchHistory(count: watchHistoryCount), .reviews(count: reviewCount), .isStared(count: isStarCount)])
                
                let sectionModels: [MyPageSectionModel] = [activitySectionModel, .management(items: [
                    .appInfo
                ])]
                
                return sectionModels
            }
        
        return sectionModel.map { .setSections($0) }
    }
}
