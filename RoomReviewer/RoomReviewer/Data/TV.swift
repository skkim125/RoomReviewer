//
//  TV.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/13/25.
//

import Foundation

struct TVList: Decodable, Equatable {
    let results: [TV]
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case results
        case totalPages = "total_pages"
    }
}

struct TV: Decodable, Equatable {
    let id: Int
    let name: String?
    let overview: String?
    let genreIDS: [Int]
    let backdropPath: String?
    let posterPath: String?
    let firstAirDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case genreIDS = "genre_ids"
        case backdropPath = "backdrop_path"
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
    }
}

extension TV {
    static var mockTV: TV {
        TV(id: 261980, name: "미지의 서울", overview: "얼굴 빼고 모든 게 다른 쌍둥이 자매가 인생을 맞바꾸는 거짓말로 진짜 사랑과 인생을 찾아가는 로맨틱 성장 드라마", genreIDS: [35, 18], backdropPath: "/m0VuPoWQhbgMjVIwAdZmmHgHQrl.jpg", posterPath: "/woGYRE5vChxqUqTBJJaOhO9Cqk6.jpg", firstAirDate: "2025-05-24")
    }
    
    static var mockTVwithNilPosterURL: TV {
        TV(id: 261980, name: "미지의 서울", overview: "얼굴 빼고 모든 게 다른 쌍둥이 자매가 인생을 맞바꾸는 거짓말로 진짜 사랑과 인생을 찾아가는 로맨틱 성장 드라마", genreIDS: [35, 18], backdropPath: nil, posterPath: nil, firstAirDate: "2025-05-24")
    }
}
