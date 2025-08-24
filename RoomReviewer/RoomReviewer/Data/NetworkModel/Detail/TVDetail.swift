//
//  TVDetail.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/23/25.
//

import Foundation

// MARK: - TVDetail
struct TVDetail: Decodable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let genres: [Genre]
    let firstAirDate: String
    let numberOfEpisodes: Int
    let certificate: ContentRatingResult
    let credits: CreditsResponse
    let createdBy: [Creator]

    enum CodingKeys: String, CodingKey {
        case id, name, overview, genres, credits
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case numberOfEpisodes = "number_of_episodes"
        case certificate = "content_ratings"
        case createdBy = "created_by"
    }
}

struct Creator: Decodable {
    let id: Int
    let name: String
    let profilePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case profilePath = "profile_path"
    }
}

struct ContentRatingResult: Decodable {
    let results: [ContentRating]
}

struct ContentRating: Decodable {
    let iso3166_1: String
    let rating: String
    
    enum CodingKeys: String, CodingKey {
        case iso3166_1 = "iso_3166_1"
        case rating
    }
}

extension TVDetail {
    func toDomain() -> MediaDetail {
        let releaseYear = String(firstAirDate.prefix(4))
        let certification = certificate.results.filter({ $0.iso3166_1 == "KR" })[0].rating
        let episodeInfo = "\(numberOfEpisodes)부작"
        
        let creators = createdBy.map { Crew(id: $0.id, name: $0.name, profilePath: $0.profilePath) }
        
        let cast = credits.cast.map {
            Cast(id: $0.id, name: $0.name, profilePath: $0.profilePath, character: $0.character)
        }
        
        return MediaDetail(
            id: id,
            title: name,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            certificate: certification,
            genres: genres.map { $0.name },
            releaseYear: releaseYear,
            runtimeOrEpisodeInfo: episodeInfo,
            cast: cast,
            creator: creators
        )
    }
}
