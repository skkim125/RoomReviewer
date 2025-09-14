//
//  NetworkError.swift
//  RoomReviewer
//
//  Created by 김상규_ on 6/6/25.
//

import Foundation

enum NetworkError: Error {
    case invalidRequest
    case invalidURL
    case invalidResponse
    case invalidData
    case decodingError
    case commonError
    case offline
    case tooManyRequests
    case serverError
    case badGateway
    case serviceUnavailable
    case timeout
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "잘못된 요청입니다.\n다시 시도해주세요."
        case .invalidURL:
            return "유효하지 않은 URL입니다.\n관리자에게 문의해주세요."
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다.\n잠시 후 다시 시도해주세요."
        case .invalidData:
            return "데이터 형식이 올바르지 않습니다.\n관리자에게 문의해주세요."
        case .decodingError:
            return "데이터 처리 중 오류가 발생했습니다.\n관리자에게 문의해주세요."
        case .commonError:
            return "알 수 없는 오류가 발생했습니다.\n다시 시도해주세요."
        case .offline:
            return "네트워크 연결을 확인해주세요."
        case .tooManyRequests:
            return "일시적으로 요청이 많아 데이터를 불러올 수 없습니다.\n잠시 후 다시 시도해 주세요."
        case .serverError:
            return "서버에 문제가 발생했습니다.\n잠시 후 다시 시도해 주세요."
        case .badGateway:
            return "게이트웨이 오류가 발생했습니다.\n잠시 후 다시 시도해 주세요."
        case .serviceUnavailable:
            return "서비스를 이용할 수 없습니다.\n잠시 후 다시 시도해 주세요."
        case .timeout:
            return "요청 시간이 초과되었습니다.\n네트워크 연결을 확인하거나 잠시 후 다시 시도해 주세요."
        }
    }
}
