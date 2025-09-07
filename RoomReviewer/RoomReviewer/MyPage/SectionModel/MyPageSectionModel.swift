//
//  MyPageSectionModel.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/5/25.
//

import Foundation
import RxDataSources

enum MyPageSectionModel {
    case myActivity(items: [MyPageSectionItem])
    case management(items: [MyPageSectionItem])
    
    var header: String? {
        switch self {
        case .myActivity:
            return "나의 활동"
        case .management:
            return "앱 관리"
        }
    }
}

extension MyPageSectionModel: SectionModelType {
    typealias Item = MyPageSectionItem
    
    var items: [MyPageSectionItem] {
        switch self {
        case .myActivity(let items):
            return items
        case .management(let items):
            return items
        }
    }
    
    init(original: MyPageSectionModel, items: [Item]) {
        switch original {
        case .myActivity:
            self = .myActivity(items: items)
        case .management:
            self = .management(items: items)
        }
    }
}

enum MyPageSectionItem {
    case reviews(count: Int)
    case watchlist(count: Int)
    case watchHistory(count: Int)
    case isStared(count: Int)
    
    case appInfo
    
    var sectionType: SectionType {
        switch self {
        case .reviews:
            return .reviewed
        case .watchlist:
            return .watchlist
        case .watchHistory:
            return .watched
        case .isStared:
            return .isStared
        default:
            return .none
        }
    }
    
    var title: String {
        switch self {
        case .reviews:
            return "평론한 컨텐츠"
        case .watchlist:
            return "보고싶어요"
        case .watchHistory:
            return "내가 본 컨텐츠"
        case .isStared:
            return "즐겨찾기"
        case .appInfo:
            return "앱 정보"
        }
    }
    
    var iconName: String {
        switch self {
        case .reviews:
            return "sunglasses.fill"
        case .watchlist:
            return "bookmark.fill"
        case .watchHistory:
            return "eye.fill"
        case .appInfo:
            return "info.circle.fill"
        case .isStared:
            return "star.fill"
        }
    }
    
    var detailText: String? {
        switch self {
        case .reviews(let count), .watchlist(let count), .watchHistory(let count), .isStared(count: let count):
            return "\(count)개"
        default:
            return nil
        }
    }
}
