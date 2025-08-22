//
//  Cast.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/22/25.
//

import Foundation

// MARK: - 도메인 모델 Cast
struct Cast: Equatable {
    let id: Int
    let name: String
    let profilePath: String?
    let character: String?
}
