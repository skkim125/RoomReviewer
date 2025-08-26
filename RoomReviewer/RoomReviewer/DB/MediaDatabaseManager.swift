//
//  MediaDataManager.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/26/25.
//

import Foundation
import CoreData
import RxSwift

protocol MediaDBManager {
    func createMedia(id: Int, title: String, overview: String?, type: String, genres: [Int], releaseDate: String?, watchedDate: Date?) -> Single<NSManagedObjectID>
    
    func fetchAllMedia() -> Single<[Media]>
    func deleteMedia(id: Int) -> Single<Void?>
    func fetchMedia(id: Int) -> Single<(Media, Date?)?>
    func updateWatchedDate(id: Int, watchedDate: Date) -> Single<Void?>
}

final class MediaDatabaseManager: MediaDBManager {
    private let stack: DataStack
    
    init(stack: DataStack) {
        self.stack = stack
    }

    // 보고 싶은 or 리뷰 작성을 위한 Media 생성 & 저장
    func createMedia(id: Int, title: String, overview: String?, type: String, genres: [Int], releaseDate: String?, watchedDate: Date?) -> Single<NSManagedObjectID> {
        
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NetworkError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            
            backgroundContext.perform {
                let entity = MediaEntity(context: backgroundContext)
                entity.id = Int64(id)
                entity.isStar = false
                entity.title = title
                entity.type = type
                entity.releaseDate = releaseDate
                entity.watchedDate = watchedDate
                entity.addedDate = Date()
                entity.genres = genres
                do {
                    try backgroundContext.save()
                    print("\(entity.title) 저장 완료")
                    
                    observer(.success(entity.objectID))
                } catch {
                    print("저장 실패: \(error.localizedDescription)")
                    
                    observer(.failure(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // 보고싶은 모든 미디어 불러오기
    func fetchAllMedia() -> Single<[Media]> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NetworkError.commonError))
                return Disposables.create()
            }
            
            let request: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "addedDate", ascending: false)
            request.sortDescriptors = [sortDescriptor]
            
            do {
                let results = try stack.viewContext.fetch(request).map { $0.toDomain() }
                observer(.success(results))
                
            } catch {
                print("Failed to fetch media: \(error)")
                observer(.success([]))
            }
            
            return Disposables.create()
        }
    }
    
    // 보고싶은 Media 삭제
    func deleteMedia(id: Int) -> Single<Void?> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.success(nil))
                return Disposables.create()
            }
            
            do {
                if let deleteObject = try stack.viewContext.fetch(MediaEntity.fetchRequest()).first(where: { $0.id == id }) {
                    let object = deleteObject
                    stack.viewContext.delete(deleteObject)
                    print("\(object.title) 삭제 완료")
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
    
    func fetchMedia(id: Int) -> Single<(Media, Date?)?> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NetworkError.commonError))
                
                return Disposables.create()
            }
            
            let context = self.stack.viewContext
            context.perform {
                let request: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "id == %d", id)
                do {
                    let data = try context.fetch(request)
                    
                    if data.isEmpty {
                        observer(.success(nil))
                    } else {
                        observer(.success((data[0].toDomain(), data[0].watchedDate ?? Date())))
                    }
                    
                } catch {
                    observer(.success(nil))
                }
            }
            return Disposables.create()
        }
    }
    
    func updateWatchedDate(id: Int, watchedDate: Date) -> Single<Void?> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NetworkError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            
            backgroundContext.perform {
                let request: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %d", id)
                
                do {
                    if let mediaToUpdate = try backgroundContext.fetch(request).first {
                        mediaToUpdate.watchedDate = watchedDate
                        try backgroundContext.save()
                        print("\(mediaToUpdate.title) 시청 날짜 업데이트 완료")
                        observer(.success(()))
                    } else {
                        observer(.failure(NetworkError.commonError))
                    }
                } catch {
                    print("업데이트 실패: \(error.localizedDescription)")
                    observer(.failure(error))
                }
            }
            
            return Disposables.create()
        }
    }
}
