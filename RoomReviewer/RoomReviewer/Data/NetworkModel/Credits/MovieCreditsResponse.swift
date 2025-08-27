//
//  MovieCreditsResponse.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/22/25.
//

import Foundation

struct MovieCreditsResponse: Decodable {
    let cast: [MovieCastResponse]
    let crew: [MovieCrewResponse]
}

struct MovieCastResponse: Decodable, Equatable {
    let id: Int
    let name: String
    let profilePath: String?
    let character: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case character
    }
}

struct MovieCrewResponse: Decodable, Equatable {
    let id: Int
    let name: String
    let profilePath: String?
    let job: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case job
    }
}
