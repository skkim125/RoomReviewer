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
    }
    
    enum Mutation {
        case setSections([MyPageSectionModel])
        case moveMyPageSection(MyPageSectionItem?)
    }
    
    struct State {
        var sections: [MyPageSectionModel] = []
        @Pulse var selectedMyPageSection: MyPageSectionItem?
    }
    
    let initialState: State = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            let sections: [MyPageSectionModel] = [
                .myActivity(items: [
                    .reviews(count: 15),
                    .watchlist(count: 8),
                    .watchHistory(count: 42)
                ]),
                .management(items: [
                    .appInfo
                ])
            ]
            return Observable.just(Mutation.setSections(sections))
            
        case .itemSelected(let indexPath):
            guard let selectedItem = currentState.sections[safe: indexPath.section]?.items[safe: indexPath.row] else {
                return .empty()
            }
            return .just(.moveMyPageSection(selectedItem))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setSections(let sections):
            newState.sections = sections
        case .moveMyPageSection(let item):
            newState.selectedMyPageSection = item
        }
        
        return newState
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
