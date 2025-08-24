//
//  Cast.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/22/25.
//

import Foundation

// MARK: - CastResponse
struct CastResponse: Decodable, Equatable {
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
