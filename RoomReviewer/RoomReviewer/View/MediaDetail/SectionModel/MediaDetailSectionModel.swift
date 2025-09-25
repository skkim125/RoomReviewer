//
//  CreditsSectionModel.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/1/25.
//

import Foundation
import RxDataSources

enum MediaDetailSectionModel: Equatable {
    case creators(items: [MediaDetailSectionItem])
    case casts(items: [MediaDetailSectionItem])
    case videos(items: [MediaDetailSectionItem])
}

enum MediaDetailSectionItem: Equatable {
    case creator(item: Crew)
    case cast(item: Cast)
    case video(item: Video)
}

extension MediaDetailSectionModel: SectionModelType {
    typealias Item = MediaDetailSectionItem
    
    var items: [MediaDetailSectionItem] {
        switch self {
        case .creators(let items), .casts(let items), .videos(let items):
            return items
        }
    }
    
    init(original: MediaDetailSectionModel, items: [Item]) {
        switch original {
        case .creators:
            self = .creators(items: items)
        case .casts:
            self = .casts(items: items)
        case .videos:
            self = .videos(items: items)
        }
    }
}

extension MediaDetailSectionModel {
    var header: String? {
        switch self {
        case .creators:
            return "크리에이터"
        case .casts:
            return "주요 출연진"
        case .videos:
            return "관련 영상"
        }
    }
}
