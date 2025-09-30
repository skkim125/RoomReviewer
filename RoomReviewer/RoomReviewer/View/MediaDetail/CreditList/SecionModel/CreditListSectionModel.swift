//
//  CreditListSectionModel.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/30/25.
//

import Foundation
import RxDataSources

enum CreditListSectionModel: Equatable {
    case casts(items: [CreditListSectionItem])
}

extension CreditListSectionModel: SectionModelType {
    typealias Item = CreditListSectionItem
    
    var items: [CreditListSectionItem] {
        switch self {
        case .casts(items: let item):
            return item.map { $0 }
        }
    }
    
    init(original: CreditListSectionModel, items: [Item]) {
        switch original {
        case .casts(let items):
            self = .casts(items: items)
        }
    }
}

enum CreditListSectionItem: Equatable {
    case cast(Cast)
    
}

