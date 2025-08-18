//
//  CoreDataStack.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/17/25.
//

// CoreDataStack.swift

import Foundation
import CoreData

protocol DataStack {
    var viewContext: NSManagedObjectContext { get }
    func newBackgroundContext() -> NSManagedObjectContext
}

final class CoreDataStack: DataStack {
    private let modelName: String
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Core Data 로딩 실패: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName: String) {
        self.modelName = modelName
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
}
