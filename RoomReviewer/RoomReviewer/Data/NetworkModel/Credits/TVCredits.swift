//
//  TVCredits.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/22/25.
//

import Foundation

struct TVCredits: Decodable {
    let id: Int
    let cast: [TVCast]
    let crew: [TVCrew]
}

struct TVCast: Decodable {
    let id: Int
    let name: String
    let profilePath: String?
    let roles: [Role]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case roles
    }
}

struct TVCrew: Decodable {
    let id: Int
    let name: String
    let profilePath: String?
    let jobs: [TVJob]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case jobs
    }
}

struct TVJob: Decodable {
    let job: String

    enum CodingKeys: String, CodingKey {
        case job
    }
}

struct Role: Decodable {
    let character: String

    enum CodingKeys: String, CodingKey {
        case character
    }
}

extension TVCast {
    func toDomain() -> Cast {
        return Cast(id: self.id, name: self.name, profilePath: self.profilePath, character: self.roles[0].character)
    }
}

extension TVCrew {
    func toDomain() -> Crew {
        return Crew(id: self.id, name: self.name, profilePath: self.profilePath, department: self.jobs[0].job)
    }
}
