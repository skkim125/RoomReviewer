//
//  HomeSectionModel.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/22/25.
//

import Foundation
import RxDataSources

enum HomeSectionModel: Equatable {
    case trend(item: [HomeSectionItem])
    case tv(item: [HomeSectionItem])
    case movie(item: [HomeSectionItem])
    
    var header: String? {
        switch self {
        case .trend:
            return "모두가 주목하는 콘텐츠"
        case .tv:
            return "요즘 핫한 K 드라마"
        case .movie:
            return "요즘 핫한 영화"
        }
    }
}

extension HomeSectionModel: SectionModelType {
    typealias Item = HomeSectionItem
    
    var items: [HomeSectionItem] {
        switch self {
        case .trend(item: let item), .tv(item: let item), .movie(item: let item):
            return item.map { $0 }
        }
    }
    
    init(original: HomeSectionModel, items: [Item]) {
        switch original {
        case .trend(let items):
            self = .trend(item: items)
        case .tv(let items):
            self = .tv(item: items)
        case .movie(let items):
            self = .movie(item: items)
        }
    }
}

enum HomeSectionItem: Equatable {
    case trend(item: Media)
    case tv(item: Media)
    case movie(item: Media)
}
