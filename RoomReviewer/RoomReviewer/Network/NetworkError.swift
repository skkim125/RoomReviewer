//
//  NetworkError.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/6/25.
//

import Foundation

enum NetworkError: Error {
    case invalidRequest
    case invalidURL
    case invalidResponse
    case invalidData
    case decodingError
    case commonError
}
