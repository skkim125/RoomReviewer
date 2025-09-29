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
    @NSManaged public var tier: String?
    @NSManaged public var certificate: String?
    @NSManaged public var runtimeOrEpisodeInfo: String?
    @NSManaged public var review: ReviewEntity?
    @NSManaged public var crews: NSSet?
    @NSManaged public var casts: NSSet?
    @NSManaged public var videos: NSSet?
}

// MARK: Generated accessors for crews
extension MediaEntity {
    public var crewArray: [CrewEntity] {
        guard let set = self.crews as? Set<CrewEntity> else { return [] }
        return set.sorted { $0.index < $1.index }
    }

    @objc(addCrewsObject:)
    @NSManaged public func addToCrews(_ value: CrewEntity)

    @objc(removeCrewsObject:)
    @NSManaged public func removeFromCrews(_ value: CrewEntity)

    @objc(addCrews:)
    @NSManaged public func addToCrews(_ values: NSSet)

    @objc(removeCrews:)
    @NSManaged public func removeFromCrews(_ values: NSSet)
}

// MARK: Generated accessors for casts
extension MediaEntity {
    public var castArray: [CastEntity] {
        guard let set = self.casts as? Set<CastEntity> else { return [] }
        return set.sorted { $0.index < $1.index }
    }

    @objc(addCastsObject:)
    @NSManaged public func addToCasts(_ value: CastEntity)

    @objc(removeCastsObject:)
    @NSManaged public func removeFromCasts(_ value: CastEntity)

    @objc(addCasts:)
    @NSManaged public func addToCasts(_ values: NSSet)

    @objc(removeCasts:)
    @NSManaged public func removeFromCasts(_ values: NSSet)
}

extension MediaEntity {
    public var videoArray: [VideoEntity] {
        guard let set = self.videos as? Set<VideoEntity> else { return [] }
        return set.sorted { $0.index < $1.index }
    }
    
    @objc(addVideosObject:)
    @NSManaged public func addToVideos(_ value: VideoEntity)

    @objc(removeVideosObject:)
    @NSManaged public func removeFromVideos(_ value: VideoEntity)
    
    @objc(addVideos:)
    @NSManaged public func addToVideos(_ values: NSSet)

    @objc(removeVideos:)
    @NSManaged public func removeFromVideos(_ values: NSSet)
}

extension MediaEntity : Identifiable {
    func toDomain() -> Media {
        return Media(id: Int(self.id), mediaType: MediaType(rawValue: self.type) ?? .person, title: self.title, overview: self.overview, posterPath: self.posterURL, backdropPath: self.backdropURL, genreIDS: self.genres, releaseDate: self.releaseDate, watchedDate: self.watchedDate)
    }
    
    func toMediaDetail() -> MediaDetail {
        let cast = self.castArray.map { $0.toDomain() }
        let creator = self.crewArray.map { $0.toDomain() }
        let video = self.videoArray.map { $0.toDomain() }
        let releaseYear = String(self.releaseDate?.prefix(4) ?? "")
        let genres = API.convertGenreString(self.genres)

        return MediaDetail(
            id: Int(self.id),
            title: self.title,
            overview: self.overview ?? "",
            posterPath: self.posterURL,
            backdropPath: self.backdropURL,
            certificate: self.certificate ?? "정보 없음",
            genres: genres,
            releaseYear: releaseYear,
            runtimeOrEpisodeInfo: self.runtimeOrEpisodeInfo ?? "정보 없음",
            cast: cast,
            creator: creator,
            video: video
        )
    }
}
