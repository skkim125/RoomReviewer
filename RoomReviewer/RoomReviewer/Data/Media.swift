//
//  Media.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/8/25.
//

import Foundation

// MARK: - Media
struct MediaResult: Decodable {
    let page: Int
    let results: [Media]
    let totalPages, totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Result
struct Media: Decodable, Equatable {
    let backdropPath: String?
    let id: Int
    let title, originalTitle: String?
    let overview, posterPath: String?
    let mediaType: MediaType?
    let genreIDS: [Int]
    let popularity: Double
    let releaseDate: String?
    let firstAirDate: String?
    let video: Bool?
    let name, originalName: String?
    let originCountry: [String]?

    enum CodingKeys: String, CodingKey {
        case backdropPath = "backdrop_path"
        case id, title
        case originalTitle = "original_title"
        case overview
        case posterPath = "poster_path"
        case mediaType = "media_type"
        case genreIDS = "genre_ids"
        case popularity
        case releaseDate = "release_date"
        case video
        case name
        case originalName = "original_name"
        case firstAirDate = "first_air_date"
        case originCountry = "origin_country"
    }
}

enum MediaType: String, Decodable {
    case movie = "movie"
    case tv = "tv"
}

extension Media {
    static var mockMedia: Media {
        Media(
            backdropPath: "/m0VuPoWQhbgMjVIwAdZmmHgHQrl.jpg",
            id: 261980,
            title: nil,
            originalTitle: nil,
            overview: "얼굴 빼고 모든 게 다른 쌍둥이 자매가 인생을 맞바꾸는 거짓말로 진짜 사랑과 인생을 찾아가는 로맨틱 성장 드라마",
            posterPath: "/woGYRE5vChxqUqTBJJaOhO9Cqk6.jpg",
            mediaType: .tv,
            genreIDS: [35, 18],
            popularity: 24.141,
            releaseDate: nil,
            firstAirDate: "2025-05-24",
            video: nil,
            name: "미지의 서울",
            originalName: "미지의 서울",
            originCountry: ["KR"]
        )
    }

    static var mockMediaWithNilPoster: Media {
        Media(
            backdropPath: "/m0VuPoWQhbgMjVIwAdZmmHgHQrl.jpg",
            id: 261980,
            title: nil,
            originalTitle: nil,
            overview: "얼굴 빼고 모든 게 다른 쌍둥이 자매가 인생을 맞바꾸는 거짓말로 진짜 사랑과 인생을 찾아가는 로맨틱 성장 드라마",
            posterPath: nil,
            mediaType: .tv,
            genreIDS: [35, 18],
            popularity: 24.141,
            releaseDate: nil,
            firstAirDate: "2025-05-24",
            video: nil,
            name: "미지의 서울",
            originalName: "미지의 서울",
            originCountry: ["KR"]
        )
    }
}
