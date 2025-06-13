//
//  TMDBTarget.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/13/25.
//

import Foundation

enum TMDBTargetType {
    case movie
    case tv
}

extension TMDBTargetType: TargetType {
    
    var baseURL: String {
        return API.baseURL
    }
    
    var path: String {
        switch self {
        case .movie:
            "discover/movie"
        case .tv:
            "discover/tv"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .movie:
            return .get
        case .tv:
            return .get
        }
    }
    
    var header: [String : String]? {
        return [
            API.authorization: API.key
        ]
    }
    
    var query: [URLQueryItem]? {
        switch self {
        case .movie:
            return [
                URLQueryItem(name: "with_original_language", value: "ko"),
                URLQueryItem(name: "sort_by", value: "popularity.desc"),
                URLQueryItem(name: "air_date.gte", value: "2025-05-01"),
                URLQueryItem(name: "air_date.gte", value: "2025-06-04"),
            ]
        case .tv:
            return [
                URLQueryItem(name: "language", value: "ko-KR"),
                URLQueryItem(name: "watch_region", value: "KR"),
                URLQueryItem(name: "with_genres", value: "18|10759|16|35|80|9648|10765|10768|10751"),
                URLQueryItem(name: "with_watch_providers", value: "337|8|356|350|1796|1881|1883"),
                URLQueryItem(name: "with_original_language", value: "ko"),
                URLQueryItem(name: "sort_by", value: "popularity.desc"),
                URLQueryItem(name: "first_air_date.gte", value: "2025-05-01"),
                URLQueryItem(name: "air_date.lte", value: "2025-06-04"),
            ]
        }
    }
    
    var body: Data? {
        switch self {
        case .movie:
            nil
        case .tv:
            nil
        }
    }
}

enum MockTargetType: TargetType {
    case movie
    
    var baseURL: String {
        return API.baseURL
    }
    
    var path: String {
        switch self {
        case .movie:
            "discover/movie"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .movie:
            return .get
        }
    }
    
    var header: [String : String]? {
        return [
            API.authorization: API.key
        ]
    }
    
    var query: [URLQueryItem]? {
        switch self {
        case .movie:
            return [
                URLQueryItem(name: "with_original_language", value: "ko"),
                URLQueryItem(name: "sort_by", value: "popularity.desc"),
                URLQueryItem(name: "air_date.gte", value: "2025-05-01"),
                URLQueryItem(name: "air_date.gte", value: "2025-06-04"),
            ]
        }
    }
    
    var body: Data? {
        switch self {
        case .movie:
            nil
        }
    }
}
