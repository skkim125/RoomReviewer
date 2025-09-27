//
//  ImageEndPoint.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/27/25.
//

import Foundation

enum ImageURLType {
    case tmdbImage(path: String)
    case youtubeThumbnail(key: String)
}

struct ImageEndpoint {
    let type: ImageURLType
    
    var cacheKey: String {
        switch type {
        case .tmdbImage(let path):
            return path
        case .youtubeThumbnail(let key):
            return "youtube_\(key)"
        }
    }
    
    var fullURL: URL? {
        let urlString: String
        switch type {
        case .tmdbImage(let path):
            urlString = API.tmdbImageURL + path
        case .youtubeThumbnail(let key):
            urlString = API.youtubeThumnailURL + key + "/hqdefault.jpg"
        }
        return URL(string: urlString)
    }
}
