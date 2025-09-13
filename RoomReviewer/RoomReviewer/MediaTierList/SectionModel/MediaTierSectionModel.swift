//
//  MediaTierSectionModel.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/10/25.
//

import UIKit
import RxDataSources

enum Tier: String, CaseIterable {
    case S, A, B, C, D
    
    var title: String {
        return "\(self.rawValue) Tier"
    }
    
    var color: UIColor {
        switch self {
        case .S:
            return .systemRed
        case .A:
            return .systemOrange
        case .B:
            return .systemYellow
        case .C:
            return .systemGreen
        case .D:
            return .systemBlue
        }
    }
}

enum MediaTierListItem: IdentifiableType, Equatable, Hashable {
    case ranked(media: Media)
    case unranked(media: Media)
    
    var identity: String {
        switch self {
        case .ranked(let media):
            return "media-\(media.id)"
        case .unranked(let media):
            return "media-\(media.id)"
        }
    }
    
    var media: Media {
        switch self {
        case .ranked(let media), .unranked(let media):
            return media
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(media)
    }
}

enum MediaTierListSectionModel: AnimatableSectionModelType {
    case tier(tier: Tier, items: [MediaTierListItem])
    case unranked(items: [MediaTierListItem])
    
    var identity: String { return title }
    var items: [MediaTierListItem] {
        switch self {
        case .tier(_, let items):
            return items
        case .unranked(let items):
            return items
        }
    }
    
    init(original: MediaTierListSectionModel, items: [Item]) {
        switch original {
        case .tier(let tier, _):
            self = .tier(tier: tier, items: items)
        case .unranked:
            self = .unranked(items: items)
        }
    }

    var title: String {
        switch self {
        case .tier(let tier, _):
            return tier.title
        case .unranked:
            return "미디어 보관함"
        }
    }
}
