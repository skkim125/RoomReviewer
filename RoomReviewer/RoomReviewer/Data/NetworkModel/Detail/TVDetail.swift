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
    let createdBy: [Creator]
    let aggregateCredits: TVCreditsResponse
    let videos: DetailVideoResponse

    enum CodingKeys: String, CodingKey {
        case id, name, overview, genres, videos
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case numberOfEpisodes = "number_of_episodes"
        case certificate = "content_ratings"
        case createdBy = "created_by"
        case aggregateCredits = "aggregate_credits"
    }
}

struct Creator: Decodable, Equatable {
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
        let certificationOfKR = certificate.results.filter({ $0.iso3166_1 == "KR" })
        let certification: String
        if certificationOfKR.isEmpty {
            certification = "업데이트 예정"
        } else {
            certification = certificationOfKR[0].rating + "세 이상"
        }
        
        let episodeInfo = "\(numberOfEpisodes)부작"
        
        let aggregateCrews = aggregateCredits.crew.filter { $0.department == "Directing" || $0.department == "Writing" }.map { Crew(id: $0.id, name: $0.name, department: $0.department, profilePath: $0.profilePath) }
        
        let creditedByCrews = createdBy.map { Crew(id: $0.id, name: $0.name, department: "Directing", profilePath: $0.profilePath) }
        
        let cast = aggregateCredits.cast.map {
            Cast(id: $0.id, name: $0.name, profilePath: $0.profilePath, character: $0.roles?[0].character ?? "")
        }
        
        let videos = videos.results.map {
            Video(name: $0.name, key: $0.key, site: $0.site, id: $0.id, publishedDate: $0.publishedAt)
        }.filter { $0.site == "YouTube" }
        
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
            creator: aggregateCrews.isEmpty ? creditedByCrews : aggregateCrews,
            video: videos
        )
    }
}

struct DetailVideoResponse: Decodable {
    let results: [VideoResponse]
    
    enum CodingKeys: String, CodingKey {
        case results
    }
}

struct VideoResponse: Decodable {
    let name: String
    let key: String
    let site: String
    let id: String
    let publishedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case key = "key"
        case site = "site"
        case id = "id"
        case publishedAt = "published_at"
    }
}
