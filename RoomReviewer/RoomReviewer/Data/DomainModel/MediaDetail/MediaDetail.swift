//
//  MediaDetail.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/23/25.
//

import Foundation

struct MediaDetail {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let certificate: String
    let genres: [String]
    let releaseYear: String
    let runtimeOrEpisodeInfo: String
    let cast: [Cast]
    let creator: [Crew]
//    let watchProviders: [Provider]
}

struct Cast: Decodable, Equatable {
    let id: Int
    let name: String
    let profilePath: String?
    let character: String?
    var index: Int?
}

struct Crew: Decodable, Equatable {
    let id: Int
    let name: String
    let department: String?
    let profilePath: String?
}
