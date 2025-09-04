//
//  CrewEntity+CoreDataProperties.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/4/25.
//
//

import Foundation
import CoreData


extension CrewEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CrewEntity> {
        return NSFetchRequest<CrewEntity>(entityName: "Crew")
    }

    @NSManaged public var name: String
    @NSManaged public var department: String?
    @NSManaged public var profileURL: String?
    @NSManaged public var id: Int64
    @NSManaged public var media: MediaEntity?

}

extension CrewEntity : Identifiable {
    func toDomain() -> Crew {
        return Crew(id: Int(self.id), name: self.name, department: self.department, profilePath: self.profileURL)
    }
}
