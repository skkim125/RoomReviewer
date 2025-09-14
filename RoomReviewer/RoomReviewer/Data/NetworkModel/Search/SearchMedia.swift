//
//  SearchMedia.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/10/25.
//

import Foundation

// MARK: - SearchResult
struct SearchResult: Decodable {
    let page: Int
    let results: [Search]
    let totalPages, totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Search
struct Search: Decodable, Equatable {
    let backdropPath: String?
    let id: Int
    let title, originalTitle: String?
    let overview, posterPath: String?
    let mediaType: MediaType
    let genreIDS: [Int]?
    let releaseDate: String?
    let firstAirDate: String?
    let video: Bool?
    let name, originalName: String?
    let originCountry: [String]?
    let popularity: Double?

    enum CodingKeys: String, CodingKey {
        case backdropPath = "backdrop_path"
        case id, title
        case originalTitle = "original_title"
        case overview
        case posterPath = "poster_path"
        case mediaType = "media_type"
        case genreIDS = "genre_ids"
        case releaseDate = "release_date"
        case video
        case name
        case originalName = "original_name"
        case firstAirDate = "first_air_date"
        case originCountry = "origin_country"
        case popularity
    }
}

extension Search {
    static var mockMedia: Search {
        Search(
            backdropPath: "/m0VuPoWQhbgMjVIwAdZmmHgHQrl.jpg",
            id: 261980,
            title: nil,
            originalTitle: nil,
            overview: "얼굴 빼고 모든 게 다른 쌍둥이 자매가 인생을 맞바꾸는 거짓말로 진짜 사랑과 인생을 찾아가는 로맨틱 성장 드라마",
            posterPath: "/woGYRE5vChxqUqTBJJaOhO9Cqk6.jpg",
            mediaType: .tv,
            genreIDS: [35, 18],
            releaseDate: nil,
            firstAirDate: "2025-05-24",
            video: nil,
            name: "미지의 서울",
            originalName: "미지의 서울",
            originCountry: ["KR"],
            popularity: 7.9
        )
    }

    static var mockMediaWithNilPoster: Search {
        Search(
            backdropPath: "/m0VuPoWQhbgMjVIwAdZmmHgHQrl.jpg",
            id: 261980,
            title: nil,
            originalTitle: nil,
            overview: "얼굴 빼고 모든 게 다른 쌍둥이 자매가 인생을 맞바꾸는 거짓말로 진짜 사랑과 인생을 찾아가는 로맨틱 성장 드라마",
            posterPath: nil,
            mediaType: .tv,
            genreIDS: [35, 18],
            releaseDate: nil,
            firstAirDate: "2025-05-24",
            video: nil,
            name: "미지의 서울",
            originalName: "미지의 서울",
            originCountry: ["KR"],
            popularity: 7.9
        )
    }
}
