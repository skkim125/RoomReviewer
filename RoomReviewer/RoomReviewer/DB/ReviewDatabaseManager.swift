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
    func createReview(_ mediaObjectID: NSManagedObjectID, rating: Double, review: String, comment: String?, quote: String?) -> Single<NSManagedObjectID>
    
    func fetchAllReview() -> Single<[ReviewEntity]>
    func deleteReview(reviewObjectID: NSManagedObjectID) -> Single<Void?>
    func fetchReview(reviewObjectID: NSManagedObjectID) -> Single<ReviewEntity?>
}

final class ReviewDatabaseManager: ReviewDBManager {
    private let stack: DataStack
    
    init(stack: DataStack) {
        self.stack = stack
    }
    
    func createReview(_ mediaObjectID: NSManagedObjectID, rating: Double, review: String, comment: String?, quote: String?) -> Single<NSManagedObjectID> {
        
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NetworkError.commonError))
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
                    if let media = try backgroundContext.existingObject(with: mediaObjectID) as? MediaEntity {
                        entity.media = media
                        
                        try backgroundContext.save()
                        print("\(entity.id) 저장 완료")
                        
                        observer(.success(entity.objectID))
                    } else {
                        observer(.failure(NetworkError.commonError))
                    }
                } catch {
                    print("저장 실패: \(error.localizedDescription)")
                    
                    observer(.failure(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchAllReview() -> Single<[ReviewEntity]> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NetworkError.commonError))
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
                observer(.success([]))
            }
            
            return Disposables.create()
        }
    }
    
    func deleteReview(reviewObjectID: NSManagedObjectID) -> Single<Void?> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.success(nil))
                return Disposables.create()
            }
            
            do {
                if let deleteObject = try stack.viewContext.existingObject(with: reviewObjectID) as? ReviewEntity {
                    let object = deleteObject
                    stack.viewContext.delete(deleteObject)
                    print("\(object.media.title) (\(object.id)) 리뷰 삭제 완료")
                    observer(.success(()))
                } else {
                    observer(.failure(NetworkError.commonError))
                }
                
            } catch {
                print("Failed to fetch media: \(error)")
                observer(.success(nil))
            }
            
            return Disposables.create()
        }
    }
    
    func fetchReview(reviewObjectID: NSManagedObjectID) -> Single<ReviewEntity?>{
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NetworkError.commonError))
                
                return Disposables.create()
            }
            
            do {
                if let Object = try stack.viewContext.existingObject(with: reviewObjectID) as? ReviewEntity {
                    observer(.success(Object))
                } else {
                    observer(.failure(NetworkError.commonError))
                }
                
            } catch {
                print("Failed to fetch media: \(error)")
                observer(.success(nil))
            }
            return Disposables.create()
        }
    }
}
