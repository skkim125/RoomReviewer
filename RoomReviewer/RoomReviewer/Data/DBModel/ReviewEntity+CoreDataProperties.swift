//
//  ReviewEntity+CoreDataProperties.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/21/25.
//
//

import Foundation
import CoreData


extension ReviewEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReviewEntity> {
        return NSFetchRequest<ReviewEntity>(entityName: "Review")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var id: UUID
    @NSManaged public var rate: Double
    @NSManaged public var reviewText: String?
    @NSManaged public var viewingDate: Date?
    @NSManaged public var media: MediaEntity

}

extension ReviewEntity : Identifiable {

}
