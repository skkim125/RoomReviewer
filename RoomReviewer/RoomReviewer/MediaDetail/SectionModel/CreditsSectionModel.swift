//
//  CreditsSectionModel.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/1/25.
//

import Foundation
import RxDataSources

enum CreditsSectionModel: Equatable {
    case creators(item: [CreditsSectionItem])
    case casts(item: [CreditsSectionItem])
    
    var header: String? {
        switch self {
        case .creators:
            "크리에이터"
        case .casts:
            "주요 출연진"
        }
    }
}

extension CreditsSectionModel: SectionModelType {
    typealias Item = CreditsSectionItem
    
    var items: [CreditsSectionItem] {
        switch self {
        case .creators(item: let item), .casts(item: let item):
            return item.map { $0 }
        }
    }
    
    init(original: CreditsSectionModel, items: [Item]) {
        switch original {
        case .creators:
            self = .creators(item: items)
        case .casts:
            self = .casts(item: items)
        }
    }
}

enum CreditsSectionItem: Equatable {
    case creators(item: Crew)
    case casts(item: Cast)
}
