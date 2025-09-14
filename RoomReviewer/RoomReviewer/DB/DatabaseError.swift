//
//  DatabaseError.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/14/25.
//

import Foundation

enum DatabaseError: Error {
    case saveFailed
    case deleteFailed
    case updateFailed
    case fetchFailed
    case commonError
}

extension DatabaseError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "데이터 저장에 실패했습니다. 다시 시도해주세요."
        case .deleteFailed:
            return "데이터 삭제에 실패했습니다. 다시 시도해주세요."
        case .updateFailed:
            return "데이터 업데이트에 실패했습니다. 다시 시도해주세요."
        case .fetchFailed:
            return "데이터를 불러오는데 실패했습니다. 다시 시도해주세요."
        case .commonError:
            return "데이터베이스 처리 중 알 수 없는 오류가 발생했습니다. 다시 시도해주세요."
        }
    }
}
