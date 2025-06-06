//
//  Configuration.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/6/25.
//

import Foundation

enum API {
    static let baseURL = Bundle.main.object(
        forInfoDictionaryKey: "API_URL"
    ) as? String ?? ""
    
    static let key = Bundle.main.object(
        forInfoDictionaryKey: "API_KEY"
    ) as? String ?? ""
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
