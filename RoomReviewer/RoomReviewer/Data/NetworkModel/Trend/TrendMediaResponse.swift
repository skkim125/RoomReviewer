//
//  TrendMediaResponse.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/29/25.
//

import Foundation

struct TrendResultResponse: Decodable {
    let results: [TrendMediaResponse]

    enum CodingKeys: String, CodingKey {
        case results
    }
}

struct TrendMediaResponse: Decodable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String
    let backdropPath: String?
    let posterPath: String?
    let mediaType: MediaType
    let genreIDS: [Int]
    let releaseDate: String?
    let firstAirDate: String?

    enum CodingKeys: String, CodingKey {
        case backdropPath = "backdrop_path"
        case id, title, name
        case overview
        case posterPath = "poster_path"
        case genreIDS = "genre_ids"
        case mediaType = "media_type"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
    }
}

enum MediaTypeResponse: String, Decodable {
    case movie = "movie"
    case tv = "tv"
}
