//
//  TV.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/13/25.
//

import Foundation

struct TVList: Decodable, Equatable {
    let results: [TV]
}

struct TV: Decodable, Equatable {
    let adult: Bool
    let backdropPath: String?
    let genreIDS: [Int]
    let id: Int
    let originCountry: [String]
    let originalLanguage, originalName, overview: String?
    let popularity: Double
    let posterPath, firstAirDate, name: String?
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case genreIDS = "genre_ids"
        case id
        case originCountry = "origin_country"
        case originalLanguage = "original_language"
        case originalName = "original_name"
        case overview, popularity
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
        case name
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}

extension TV {
    static var mockTV: TV {
        TV(adult: false, backdropPath: "/m0VuPoWQhbgMjVIwAdZmmHgHQrl.jpg", genreIDS: [35, 18], id: 261980, originCountry: ["KR"], originalLanguage: "ko", originalName: "미지의 서울", overview: "얼굴 빼고 모든 게 다른 쌍둥이 자매가 인생을 맞바꾸는 거짓말로 진짜 사랑과 인생을 찾아가는 로맨틱 성장 드라마", popularity: 24.141, posterPath: "/woGYRE5vChxqUqTBJJaOhO9Cqk6.jpg", firstAirDate: "2025-05-24", name: "미지의 서울", voteAverage: 7.444, voteCount: 9)
    }
    
    static var mockTVwithNilPosterURL: TV {
        TV(adult: false, backdropPath: "/m0VuPoWQhbgMjVIwAdZmmHgHQrl.jpg", genreIDS: [35, 18], id: 261980, originCountry: ["KR"], originalLanguage: "ko", originalName: "미지의 서울", overview: "얼굴 빼고 모든 게 다른 쌍둥이 자매가 인생을 맞바꾸는 거짓말로 진짜 사랑과 인생을 찾아가는 로맨틱 성장 드라마", popularity: 24.141, posterPath: nil, firstAirDate: "2025-05-24", name: "미지의 서울", voteAverage: 7.444, voteCount: 9)
    }
}
