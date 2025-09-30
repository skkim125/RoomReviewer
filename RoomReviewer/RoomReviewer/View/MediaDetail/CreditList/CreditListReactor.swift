//
//  CreditListReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/30/25.
//

import ReactorKit
import RxDataSources
import RxSwift

final class CreditListReactor: Reactor {
    
    enum Action {
        case viewDidLoad
    }
    
    enum Mutation {
        case setSections([CreditListSectionModel])
    }
    
    struct State {
        var sections: [CreditListSectionModel] = []
        var credits: [Cast]
    }
    
    let initialState: State
    
    init(credits: [Cast]) {
        self.initialState = State(credits: credits)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            let credits = currentState.credits
            let sections = setSectionModel(credits: credits)
            return .just(.setSections(sections))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setSections(let sections):
            newState.sections = sections
        }
        return newState
    }
    
    private func setSectionModel(credits: [Cast]) -> [CreditListSectionModel] {
        let sectionModels:[CreditListSectionModel] = [CreditListSectionModel.casts(items: credits.map { CreditListSectionItem.cast($0)})]
        return sectionModels
    }
}
