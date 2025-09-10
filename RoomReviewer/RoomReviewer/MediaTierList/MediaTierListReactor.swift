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
        case moveItem(from: IndexPath, to: IndexPath)
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
            
        case .moveItem(let from, let to):
            var sections = self.currentState.sections
            let sourceItem = sections[from.section].items[from.row]
            let media: Media
            switch sourceItem {
            case .ranked(let m), .unranked(let m):
                media = m
            }
            
            if from.section == to.section {
                var items = sections[from.section].items
                
                let movedItem = items.remove(at: from.item)
                
                let insertIndex = min(to.item, items.count)
                items.insert(movedItem, at: insertIndex)
                
                sections[from.section] = MediaTierListSectionModel(original: sections[from.section], items: items)
                
                return .just(.setSections(sections))
                
            } else {
                let newItem: MediaTierListItem
                let newTier: Tier?
                switch sections[to.section] {
                case .tier(let tier, _):
                    newItem = .ranked(media: media)
                    newTier = tier
                case .unranked:
                    newItem = .unranked(media: media)
                    newTier = nil
                }
                
                var sourceItems = sections[from.section].items
                sourceItems.remove(at: from.item)
                sections[from.section] = MediaTierListSectionModel(original: sections[from.section], items: sourceItems)
                
                var destinationItems = sections[to.section].items
                destinationItems.insert(newItem, at: to.item)
                sections[to.section] = MediaTierListSectionModel(original: sections[to.section], items: destinationItems)
                
                return self.mediaDBManager.updateTier(mediaID: media.id, newTier: newTier?.rawValue)
                    .asObservable()
                    .map { .setSections(sections) }
                    .catchAndReturn(.setSections(self.currentState.sections))
            }
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
