//
//  Movie.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/10/25.
//

import Foundation

// MARK: - MovieList
struct MovieList: Decodable, Equatable {
    let results: [Movie]
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case results
        case totalPages = "total_pages"
    }
}

// MARK: - Movie
struct Movie: Decodable, Equatable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let genreIDS: [Int]
    let releaseDate: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case genreIDS = "genre_ids"
        case releaseDate = "release_date"
    }
}
