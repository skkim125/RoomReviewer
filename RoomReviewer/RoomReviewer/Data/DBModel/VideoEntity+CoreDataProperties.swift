//
//  VideoEntity+CoreDataProperties.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/29/25.
//
//

import Foundation
import CoreData


extension VideoEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VideoEntity> {
        return NSFetchRequest<VideoEntity>(entityName: "Video")
    }

    @NSManaged public var id: String
    @NSManaged public var videoName: String
    @NSManaged public var key: String
    @NSManaged public var index: Int64
    @NSManaged public var date: String?
    @NSManaged public var media: MediaEntity?

}

extension VideoEntity : Identifiable {
    func toDomain() -> Video {
        return Video(name: videoName, key: key, site: "Youtube", id: id, publishedDate: date)
    }
}
