//
//  MovieCredits.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/22/25.
//

import Foundation

struct MovieCredits: Decodable {
    let id: Int
    let cast: [MovieCast]
    let crew: [MovieCrew]
}

// MARK: - Cast
struct MovieCast: Decodable {
    let id: Int
    let name: String
    let profilePath: String?
    let character: String?
    let order: Int?
    let job: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case character
        case order
        case job
    }
}

struct MovieCrew: Decodable {
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

extension MovieCast {
    func toDomain() -> Cast {
        let character = self.character?.components(separatedBy: "/").first ?? ""
        return Cast(id: self.id, name: self.name, profilePath: self.profilePath, character: character)
    }
}

extension MovieCrew {
    func toDomain() -> Crew {
        return Crew(id: self.id, name: self.name, profilePath: self.profilePath)
    }
}
