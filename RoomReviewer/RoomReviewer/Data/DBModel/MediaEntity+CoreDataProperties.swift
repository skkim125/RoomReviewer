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
    @NSManaged public var crews: NSOrderedSet
    @NSManaged public var casts: NSOrderedSet
}

extension MediaEntity {
    public var crewArray: [CrewEntity] {
        return self.crews.array as? [CrewEntity] ?? []
    }
    
    @objc(addCrewsObject:)
    @NSManaged public func addToCrews(_ value: CrewEntity)

    @objc(removeCrewsObject:)
    @NSManaged public func removeFromCrews(_ value: CrewEntity)

    @objc(addCrews:)
    @NSManaged public func addToCrews(_ values: NSOrderedSet)

    @objc(removeCrews:)
    @NSManaged public func removeFromCrews(_ values: NSOrderedSet)
}

extension MediaEntity {
    public var castArray: [CastEntity] {
        return self.casts.array as? [CastEntity] ?? []
    }
    
    @objc(addCastsObject:)
    @NSManaged public func addToCasts(_ value: CastEntity)
    
    @objc(removeCastsObject:)
    @NSManaged public func removeFromCasts(_ value: CastEntity)
    
    @objc(addCasts:)
    @NSManaged public func addToCasts(_ values: NSOrderedSet)
    
    @objc(removeCasts:)
    @NSManaged public func removeFromCasts(_ values: NSOrderedSet)
}

extension MediaEntity : Identifiable {
    func toDomain() -> Media {
        return Media(id: Int(self.id), mediaType: MediaType(rawValue: self.type) ?? .person, title: self.title, overview: self.overview, posterPath: self.posterURL, backdropPath: self.backdropURL, genreIDS: self.genres, releaseDate: self.releaseDate, watchedDate: self.watchedDate)
    }
}
