//
//  TVCreditsResponse.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/22/25.
//

import Foundation

struct TVCreditsResponse: Decodable {
    let cast: [TVCastResponse]
    let crew: [TVCrewResponse]
}

struct TVCastResponse: Decodable {
    let id: Int
    let name: String
    let profilePath: String?
    let roles: [RoleResponse]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case roles
    }
}

struct TVCrewResponse: Decodable {
    let id: Int
    let name: String
    let profilePath: String?
    let department: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case department
    }
}

struct RoleResponse: Decodable {
    let character: String

    enum CodingKeys: String, CodingKey {
        case character
    }
}
