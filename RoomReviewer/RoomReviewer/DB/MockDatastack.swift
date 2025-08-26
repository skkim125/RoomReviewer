//
//  MockDatastack.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/26/25.
//

import Foundation
import CoreData

final class MockCoreDataStack: DataStack {
    lazy var container: NSPersistentContainer = {
        let container: NSPersistentContainer = NSPersistentContainer(name: "RoomReviewerEntity")
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { desc, error in
            precondition(desc.type == NSInMemoryStoreType)
            if let error = error { fatalError("저장소 로딩 실패: \(error)") }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()

    var viewContext: NSManagedObjectContext { container.viewContext }
    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ctx
    }
}
