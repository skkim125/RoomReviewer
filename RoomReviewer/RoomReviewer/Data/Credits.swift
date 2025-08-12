//
//  Credits.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/13/25.
//

import Foundation

// MARK: - Credit
struct Credits: Decodable {
    let cast: [Cast]
    let crew: [Crew]
}

// MARK: - Cast
struct Cast: Decodable {
    let id: Int
    let name: String
    let profilePath: String?
    let character: String
    let creditID: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case character
        case creditID = "credit_id"
    }
}

struct Crew: Decodable {
    let id: Int
    let name: String
    let profilePath: String?
    let creditID: String
    let department: String
    let job: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case creditID = "credit_id"
        case department
        case job
    }
}
