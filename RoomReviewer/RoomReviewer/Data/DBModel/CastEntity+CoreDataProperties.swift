//
//  CastEntity+CoreDataProperties.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/4/25.
//
//

import Foundation
import CoreData


extension CastEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CastEntity> {
        return NSFetchRequest<CastEntity>(entityName: "Cast")
    }

    @NSManaged public var name: String
    @NSManaged public var profileURL: String?
    @NSManaged public var character: String?
    @NSManaged public var id: Int64
    @NSManaged public var media: MediaEntity?

}

extension CastEntity : Identifiable {
    func toDomain() -> Cast {
        return Cast(id: Int(self.id), name: self.name, profilePath: self.profileURL, character: self.character)
    }
}
