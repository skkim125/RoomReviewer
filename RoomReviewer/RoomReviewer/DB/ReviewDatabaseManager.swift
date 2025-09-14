//
//  ReviewDatabaseManager.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/26/25.
//

import Foundation
import CoreData
import RxSwift

protocol ReviewDBManager {
    func createReview(_ mediaID: Int, rating: Double, review: String, comment: String?, quote: String?) -> Single<NSManagedObjectID>
    func updateReview(_ reviewObjectID: NSManagedObjectID, rating: Double, review: String, comment: String?, quote: String?) -> Single<Void>
    
    func fetchAllReview() -> Single<[ReviewEntity]>
    func deleteReview(reviewObjectID: NSManagedObjectID) -> Single<Void>
    func fetchReview(reviewObjectID: NSManagedObjectID) -> Single<ReviewEntity>
    func isReviewExists(id: Int) -> Bool
    func fetchReview(id: Int) -> ReviewEntity?
}

final class ReviewDatabaseManager: ReviewDBManager {
    private let stack: DataStack
    
    init(stack: DataStack) {
        self.stack = stack
    }
    
    func createReview(_ mediaID: Int, rating: Double, review: String, comment: String?, quote: String?) -> Single<NSManagedObjectID> {
        
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            
            backgroundContext.perform {
                let entity = ReviewEntity(context: backgroundContext)
                entity.id = UUID()
                entity.rating = rating
                entity.review = review
                entity.comment = comment
                entity.quote = quote
                entity.creationDate = Date()
                
                do {
                    let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %d", mediaID)
                    
                    if let media = try backgroundContext.fetch(fetchRequest).first {
                        entity.media = media
                        
                        try backgroundContext.save()
                        print("\(entity.id) 저장 완료")
                        
                        observer(.success(entity.objectID))
                    } else {
                        observer(.failure(DatabaseError.saveFailed))
                    }
                } catch {
                    print("저장 실패: \(error.localizedDescription)")
                    
                    observer(.failure(DatabaseError.saveFailed))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchAllReview() -> Single<[ReviewEntity]> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                return Disposables.create()
            }
            
            let request: NSFetchRequest<ReviewEntity> = ReviewEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
            request.sortDescriptors = [sortDescriptor]
            
            do {
                let results = try stack.viewContext.fetch(request)
                observer(.success(results))
                
            } catch {
                print("Failed to fetch media: \(error)")
                observer(.failure(DatabaseError.fetchFailed))
            }
            
            return Disposables.create()
        }
    }
    
    func deleteReview(reviewObjectID: NSManagedObjectID) -> Single<Void> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                return Disposables.create()
            }
            
            do {
                if let deleteObject = try stack.viewContext.existingObject(with: reviewObjectID) as? ReviewEntity {
                    let object = deleteObject
                    stack.viewContext.delete(deleteObject)
                    print("\(object.media.title) (\(object.id)) 리뷰 삭제 완료")
                    observer(.success(()))
                } else {
                    observer(.failure(DatabaseError.deleteFailed))
                }
                
            } catch {
                print("Failed to fetch media: \(error)")
                observer(.failure(DatabaseError.deleteFailed))
            }
            
            return Disposables.create()
        }
    }
    
    func fetchReview(reviewObjectID: NSManagedObjectID) -> Single<ReviewEntity>{
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                
                return Disposables.create()
            }
            
            do {
                if let Object = try stack.viewContext.existingObject(with: reviewObjectID) as? ReviewEntity {
                    observer(.success(Object))
                } else {
                    observer(.failure(DatabaseError.fetchFailed))
                }
                
            } catch {
                print("Failed to fetch media: \(error)")
                observer(.failure(DatabaseError.fetchFailed))
            }
            return Disposables.create()
        }
    }
    
    func isReviewExists(id: Int) -> Bool {
        let request = MediaEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        do {
            let medias = try stack.viewContext.fetch(request)
            if let media = medias.first {
                return media.review != nil
            } else {
                return false
            }
        } catch {
            print(error)
            return false
        }
    }
    
    func fetchReview(id: Int) -> ReviewEntity? {
        let request = MediaEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        do {
            let medias = try stack.viewContext.fetch(request)
            return medias.first?.review
        } catch {
            print(error)
            return nil
        }
    }
    
    func updateReview(_ reviewObjectID: NSManagedObjectID, rating: Double, review: String, comment: String?, quote: String?) -> Single<Void> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            
            backgroundContext.perform {
                do {
                    guard let entity = try backgroundContext.existingObject(with: reviewObjectID) as? ReviewEntity else {
                        observer(.failure(DatabaseError.updateFailed))
                        return
                    }
                    
                    entity.rating = rating
                    entity.review = review
                    entity.comment = comment
                    entity.quote = quote
                    entity.creationDate = Date() // Update modification date
                    
                    try backgroundContext.save()
                    print("Review \(entity.id) updated successfully.")
                    observer(.success(()))
                } catch {
                    print("Failed to update review: \(error.localizedDescription)")
                    observer(.failure(DatabaseError.updateFailed))
                }
            }
            return Disposables.create()
        }
    }
}
