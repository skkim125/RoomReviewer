//
//  Crew.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/22/25.
//

import Foundation

// MARK: - 도메인 모델 Crew
struct Crew: Equatable {
    let id: Int
    let name: String
    let profilePath: String?
    let department: String
}
