//
//  Media.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/12/25.
//

import Foundation

struct Media: Equatable {
    let id: Int
    let mediaType: MediaType
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let genreIDS: [Int]
    let releaseDate: String?
}

enum MediaType: String, Codable {
    case movie = "movie"
    case tv = "tv"
    case person = "person"
}

extension Media {
    static var mockTV: Media {
        Media(id: 261980, mediaType: .tv, title: "미지의 서울", overview: "얼굴 빼고 모든 게 다른 쌍둥이 자매가 인생을 맞바꾸는 거짓말로 진짜 사랑과 인생을 찾아가는 로맨틱 성장 드라마", posterPath: "/m0VuPoWQhbgMjVIwAdZmmHgHQrl.jpg", backdropPath: "/woGYRE5vChxqUqTBJJaOhO9Cqk6.jpg",  genreIDS: [35, 18], releaseDate: "2025-05-08")
    }
    
    static var mockTVwithNilPosterURL: Media {
        Media(id: 261980, mediaType: .tv, title: "미지의 서울", overview: "얼굴 빼고 모든 게 다른 쌍둥이 자매가 인생을 맞바꾸는 거짓말로 진짜 사랑과 인생을 찾아가는 로맨틱 성장 드라마", posterPath: nil, backdropPath: nil,  genreIDS: [35, 18], releaseDate: nil)
    }
}
