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
    case searchMulti(String, Int)
    case getMovieDetail(Int)
    case getTVDetail(Int)
    case movieCredits(Int)
    case tvCredits(Int)
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
        case .searchMulti:
            "search/multi"
        case .getMovieDetail(let id):
            "movie/\(id)"
        case .getTVDetail(let id):
            "tv/\(id)"
        case .movieCredits(let id):
            "movie/\(id)/credits"
        case .tvCredits(let id):
            "tv/\(id)/aggregate_credits"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .movie:
            return .get
        case .tv:
            return .get
        case .searchMulti:
            return .get
        case .getMovieDetail:
            return .get
        case .getTVDetail:
            return .get
        case .movieCredits:
            return .get
        case .tvCredits:
            return .get
        }
    }
    
    var header: [String : String]? {
        return [
            API.authorization: API.key,
            API.contentType: API.jsonContentType
        ]
    }
    
    var query: [URLQueryItem]? {
        switch self {
        case .movie:
            return [
                URLQueryItem(name: "language", value: "ko-KR"),
                URLQueryItem(name: "region", value: "KR"),
                URLQueryItem(name: "watch_region", value: "KR"),
                URLQueryItem(name: "with_release_type", value: "3|4"),
                URLQueryItem(name: "primary_release_date.gte", value: "2025-06-01"),
                URLQueryItem(name: "primary_release_date.lte", value: "2025-07-12"),
                URLQueryItem(name: "release_date.gte", value: "2025-06-01"),
                URLQueryItem(name: "release_date.lte", value: "2025-07-12"),
                URLQueryItem(name: "sort_by", value: "popularity.desc"),
                URLQueryItem(name: "vote_count.gte", value: "50"),
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
                URLQueryItem(name: "first_air_date.lte", value: "2025-07-12"),
                URLQueryItem(name: "air_date.gte", value: "2025-05-01"),
                URLQueryItem(name: "air_date.lte", value: "2025-07-12"),
                URLQueryItem(name: "vote_count.gte", value: "5"),
                URLQueryItem(name: "without_genres", value: "10764,99")
            ]
        case .searchMulti(let query, let page):
            return [
                URLQueryItem(name: "query", value: "\(query)"),
                URLQueryItem(name: "language", value: "ko-KR"),
                URLQueryItem(name: "page", value: "\(page)"),
            ]
        case .movieCredits:
            return [
                URLQueryItem(name: "language", value: "ko-KR")
            ]
        case .tvCredits:
            return [
                URLQueryItem(name: "language", value: "ko-KR")
            ]
        case .getMovieDetail:
            return [
                URLQueryItem(name: "append_to_response", value: "credits,release_dates,watch/providers"),
                URLQueryItem(name: "language", value: "ko-KR"),
                URLQueryItem(name: "region", value: "KR"),
            ]
        case .getTVDetail:
            return [
                URLQueryItem(name: "append_to_response", value: "aggregate_credits,content_ratings,recommendations,watch/providers"),
                URLQueryItem(name: "language", value: "ko-KR"),
                URLQueryItem(name: "region", value: "KR"),
            ]
        }
    }
    
    var body: Data? {
        switch self {
        case .movie:
            return nil
        case .tv:
            return nil
        case .searchMulti:
            return nil
        case .movieCredits:
            return nil
        case .tvCredits:
            return nil
        case .getMovieDetail:
            return nil
        case .getTVDetail:
            return nil
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
