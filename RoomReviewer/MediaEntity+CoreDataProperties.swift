//
//  MediaEntity+CoreDataProperties.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/21/25.
//
//

import Foundation
import CoreData


extension MediaEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaEntity> {
        return NSFetchRequest<MediaEntity>(entityName: "Media")
    }

    @NSManaged public var addedDate: Date?
    @NSManaged public var backdropURL: String?
    @NSManaged public var genres: [Int]
    @NSManaged public var id: Int64
    @NSManaged public var isStar: Bool
    @NSManaged public var overview: String?
    @NSManaged public var posterURL: String?
    @NSManaged public var releaseDate: String?
    @NSManaged public var title: String
    @NSManaged public var type: String
    @NSManaged public var watchedDate: Date?
    @NSManaged public var review: ReviewEntity?

}

extension MediaEntity : Identifiable {
    func toDomain() -> Media {
        return Media(id: Int(self.id), mediaType: MediaType(rawValue: self.type) ?? .person, title: self.title, overview: self.overview, posterPath: self.posterURL, backdropPath: self.backdropURL, genreIDS: self.genres, releaseDate: self.releaseDate, watchedDate: self.watchedDate)
    }
}
