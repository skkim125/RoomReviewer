//
//  MovieDetail.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/23/25.
//

import Foundation

// MARK: - MovieDetail
struct MovieDetail: Decodable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let genres: [Genre]
    let releaseDate: ReleaseDateResult
    let runtime: Int?
    let credits: MovieCreditsResponse
    let watchProviders: WatchProviders

    enum CodingKeys: String, CodingKey {
        case id, title, overview, genres, runtime, credits
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_dates"
        case watchProviders = "watch/providers"
    }
}

struct Genre: Decodable {
    let name: String
}

struct CreditsResponse: Decodable {
    let cast: [MovieCastResponse]
    let crew: [MovieCrewResponse]
}

struct ReleaseDateResult: Decodable {
    let results: [ReleaseDateInfo]
}

// MARK: - ReleaseDateInfo
struct ReleaseDateInfo: Decodable {
    let iso3166_1: String
    let releaseDates: [ReleaseDate]

    enum CodingKeys: String, CodingKey {
        case iso3166_1 = "iso_3166_1"
        case releaseDates = "release_dates"
    }
}

// MARK: - ReleaseDate
struct ReleaseDate: Decodable {
    let certification: String
    let note: String
    let releaseDate: String

    enum CodingKeys: String, CodingKey {
        case certification
        case note
        case releaseDate = "release_date"
    }
}

struct WatchProviders: Decodable {
    let results: [String: CountryProviders]
}

struct CountryProviders: Decodable {
    let flatrate: [Provider]?
}

struct Provider: Decodable {
    let providerName: String
    let logoPath: String
    
    enum CodingKeys: String, CodingKey {
        case providerName = "provider_name"
        case logoPath = "logo_path"
    }
}

extension MovieDetail {
    func toDomain() -> MediaDetail {
        let filterReleaseDate = releaseDate.results.filter { $0.iso3166_1 == "KR" }
        let certificate: String
        let releaseYear: String
        if filterReleaseDate.isEmpty {
            certificate = "정보 없음"
            releaseYear = "정보 없음"
        } else {
            certificate = filterReleaseDate[0].releaseDates[0].certification + "세 이상"
            releaseYear = String(filterReleaseDate[0].releaseDates[0].releaseDate.prefix(4))
        }
        let runtimeInfo = "\(runtime ?? 0)분"
        
        let directors = credits.crew.filter { $0.department == "Directing" || $0.department == "Writing" }.map { Crew(id: $0.id, name: $0.name, department: $0.department, profilePath: $0.profilePath) }
        
        let cast = credits.cast.map {
            Cast(id: $0.id, name: $0.name, profilePath: $0.profilePath, character: $0.character)
        }
        
        return MediaDetail(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            certificate: certificate,
            genres: genres.map { $0.name },
            releaseYear: releaseYear,
            runtimeOrEpisodeInfo: runtimeInfo,
            cast: cast,
            creator: directors,
        )
    }
}
