//
//  HomeSectionModel.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/22/25.
//

import Foundation
import RxDataSources

enum HomeSectionModel: Equatable {
    case tv(item: [HomeSectionItem])
    case movie(item: [HomeSectionItem])
    
    var header: String {
        switch self {
        case .tv:
            return "요즘 뜨는 TV 드라마"
        case .movie:
            return "요즘 뜨는 영화"
        }
    }
}

extension HomeSectionModel: SectionModelType {
    typealias Item = HomeSectionItem
    
    var items: [HomeSectionItem] {
        switch self {
        case .tv(item: let item), .movie(item: let item):
            return item.map { $0 }
        }
    }
    
    init(original: HomeSectionModel, items: [Item]) {
        switch original {
        case .tv(let items):
            self = .tv(item: items)
        case .movie(let items):
            self = .movie(item: items)
        }
    }
}

enum HomeSectionItem: Equatable {
    case tv(item: TV)
    case movie(item: TV)
}
