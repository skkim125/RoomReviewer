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
                let watchlist = mediaEntities.filter { $0.addedDate != nil }.map { $0.toDomain() }
                let watchHistory = mediaEntities.filter { $0.watchedDate != nil }.map { $0.toDomain() }
                let review = mediaEntities.filter { $0.review != nil }.map { $0.toDomain() }
                let isStar = mediaEntities.filter { $0.isStar }.map { $0.toDomain() }
                
                let activitySectionModel: MyPageSectionModel = .myActivity(items: [.watchlist(watchlist), .watchHistory(watchHistory), .reviews(review), .isStared(isStar)])
                
                let sectionModels: [MyPageSectionModel] = [activitySectionModel, .management(items: [
                    .appInfo
                ])]
                
                return sectionModels
            }
        
        return sectionModel.map { .setSections($0) }
    }
}
