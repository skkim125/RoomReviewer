//
//  MediaTierListReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/10/25.
//

import Foundation
import ReactorKit
import RxSwift

final class MediaTierListReactor: Reactor {
    enum Action {
        case viewDidLoad
    }
    
    enum Mutation {
        case setSections([MediaTierListSectionModel])
    }
    
    struct State {
        var sections: [MediaTierListSectionModel] = []
    }
    
    var initialState: State
    private let mediaDBManager: MediaDBManager
    
    init(mediaDBManager: MediaDBManager) {
        self.mediaDBManager = mediaDBManager
        self.initialState = State()
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return mediaDBManager.fetchAllMedia()
                .asObservable()
                .map { mediaEntities in
                    self.createSections(from: mediaEntities)
                }
                .map(Mutation.setSections)
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
    
    private func createSections(from mediaEntities: [MediaEntity]) -> [MediaTierListSectionModel] {
        var tiers: [Tier: [Media]] = [:]
        var unrankedMedia: [Media] = []
        
        for entity in mediaEntities {
            if let tierString = entity.tier, let tier = Tier(rawValue: tierString) {
                if tiers[tier] == nil { tiers[tier] = [] }
                tiers[tier]?.append(entity.toDomain())
            } else {
                unrankedMedia.append(entity.toDomain())
            }
        }
        
        let tierSections = Tier.allCases.map { tier -> MediaTierListSectionModel in
            let items = (tiers[tier] ?? []).map { MediaTierListItem.ranked(media: $0) }
            return .tier(tier: tier, items: items)
        }
        
        let unrankedItems = unrankedMedia.map { MediaTierListItem.unranked(media: $0) }
        let unrankedSection = MediaTierListSectionModel.unranked(items: unrankedItems)
        
        return tierSections + [unrankedSection]
    }
}
