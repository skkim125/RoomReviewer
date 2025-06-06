//
//  TargetType.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/6/25.
//

import Foundation

protocol TargetType {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var header: [String: String]? { get }
    var query: [URLQueryItem]? { get }
    var body: Data? { get }
}

extension TargetType {
    func asURLRequest() throws -> URLRequest {
        guard let baseURL = URL(string: baseURL + path) else { throw NetworkError.invalidURL }
        var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = query
        
        guard let url = components?.url else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        
        request.timeoutInterval = 5
        request.allHTTPHeaderFields = header
        request.httpMethod = method.rawValue
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
}
