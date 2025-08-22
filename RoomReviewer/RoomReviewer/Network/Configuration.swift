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
    
    static let tmdbImageURL = Bundle.main.object(
        forInfoDictionaryKey: "API_IMAGE_URL"
    ) as? String ?? ""
    
    static let authorization = "Authorization"
    static let contentType = "accept"
    static let jsonContentType = "application/json"

    static func convertGenreString(_ array: [Int]) -> [String] {
        let genres = array.compactMap { Genre(rawValue: $0) }
        
        return genres.map { $0.name }.sorted()
    }

    enum Genre: Int, CaseIterable {
        // 영화 & TV 시리즈 장르
        case action = 28
        case adventure = 12
        case animation = 16
        case comedy = 35
        case crime = 80
        case documentary = 99
        case drama = 18
        case family = 10751
        case fantasy = 14
        case history = 36
        case horror = 27
        case music = 10402
        case mystery = 9648
        case romance = 10749
        case scienceFiction = 878
        case tvMovie = 10770
        case thriller = 53
        case war = 10752
        case western = 37
        
        // TV 시리즈 장르
        case actionAndAdventure = 10759
        case kids = 10762
        case news = 10763
        case reality = 10764
        case sciFiAndFantasy = 10765
        case soap = 10766
        case talk = 10767
        case warAndPolitics = 10768

        // 장르 이름
        var name: String {
            switch self {
            case .action:
                return "액션"
            case .adventure:
                return "모험"
            case .animation:
                return "애니메이션"
            case .comedy:
                return "코미디"
            case .crime:
                return "범죄"
            case .documentary:
                return "다큐멘터리"
            case .drama:
                return "드라마"
            case .family:
                return "가족"
            case .fantasy:
                return "판타지"
            case .history:
                return "역사"
            case .horror:
                return "공포"
            case .music:
                return "음악"
            case .mystery:
                return "미스터리"
            case .romance:
                return "로맨스"
            case .scienceFiction:
                return "SF"
            case .tvMovie:
                return "TV 영화"
            case .thriller:
                return "스릴러"
            case .war:
                return "전쟁"
            case .western:
                return "서부"
            case .actionAndAdventure:
                return "액션 & 모험"
            case .kids:
                return "키즈"
            case .news:
                return "뉴스"
            case .reality:
                return "리얼리티"
            case .sciFiAndFantasy:
                return "SF & 판타지"
            case .soap:
                return "연속극"
            case .talk:
                return "토크쇼"
            case .warAndPolitics:
                return "전쟁 & 정치"
            }
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
