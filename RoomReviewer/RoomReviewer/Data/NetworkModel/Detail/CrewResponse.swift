//
//  Crew.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/22/25.
//

import Foundation

// MARK: - CrewResponse
struct CrewResponse: Decodable, Equatable {
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
