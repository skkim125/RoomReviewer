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
    func createMedia(id: Int, title: String, overview: String?, type: String, posterURL: String?, backdropURL: String?, genres: [Int], releaseDate: String?, watchedDate: Date?, creators: [Crew], casts: [Cast], addedDate: Date?, certificate: String?, runtimeOrEpisodeInfo: String?) -> Single<NSManagedObjectID>
    
    func fetchAllMedia() -> Single<[MediaEntity]>
    func deleteMedia(id: Int) -> Single<Void>
    func fetchMedia(id: Int) -> Single<(Bool, NSManagedObjectID?, Bool, Date?, Bool)?>
    func fetchMediaEntity(id: Int) -> Single<MediaEntity?>
    func updateMediaDetail(id: Int, mediaDetail: MediaDetail) -> Single<Bool> 
    func updateWatchedDate(id: Int, watchedDate: Date?) -> Single<NSManagedObjectID>
    func updateIsStared(id: Int, isStar: Bool) -> Single<Bool>
    func updateIsWatchlist(id: Int, isWatchlist: Bool) -> Single<Bool>
    func updateTier(mediaID: Int, newTier: String?) -> Single<Void>
}

final class MediaDatabaseManager: MediaDBManager {
    private let stack: DataStack
    
    init(stack: DataStack) {
        self.stack = stack
    }

    // 보고 싶은 or 리뷰 작성을 위한 Media 생성 & 저장
    func createMedia(id: Int, title: String, overview: String?, type: String, posterURL: String?, backdropURL: String?, genres: [Int], releaseDate: String?, watchedDate: Date?, creators: [Crew], casts: [Cast], addedDate: Date?, certificate: String?, runtimeOrEpisodeInfo: String?) -> Single<NSManagedObjectID> {
        
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NetworkError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            
            backgroundContext.perform {
                let mediaEntity = MediaEntity(context: backgroundContext)
                mediaEntity.id = Int64(id)
                mediaEntity.isStar = false
                mediaEntity.title = title
                mediaEntity.overview = overview
                mediaEntity.type = type
                mediaEntity.posterURL = posterURL
                mediaEntity.backdropURL = backdropURL
                mediaEntity.releaseDate = releaseDate
                mediaEntity.watchedDate = watchedDate
                mediaEntity.addedDate = addedDate
                mediaEntity.genres = genres
                mediaEntity.certificate = certificate
                mediaEntity.runtimeOrEpisodeInfo = runtimeOrEpisodeInfo
                
                for (index, cast) in casts.enumerated() {
                    let castEntity = CastEntity(context: backgroundContext)
                    
                    castEntity.id = Int64(cast.id)
                    castEntity.name = cast.name
                    castEntity.character = cast.character
                    castEntity.profileURL = cast.profilePath
                    castEntity.index = Int64(index) // 인덱스 저장
                    
                    mediaEntity.addToCasts(castEntity)
                }
                
                for (index, crew) in creators.enumerated() {
                    let crewEntity = CrewEntity(context: backgroundContext)
                    
                    crewEntity.id = Int64(crew.id)
                    crewEntity.name = crew.name
                    crewEntity.department = crew.department
                    crewEntity.profileURL = crew.profilePath
                    crewEntity.index = Int64(index) // 인덱스 저장
                    
                    mediaEntity.addToCrews(crewEntity)
                }
                
                do {
                    try backgroundContext.save()
                    print("\(mediaEntity.title) 저장 완료")
                    
                    observer(.success(mediaEntity.objectID))
                } catch {
                    print("저장 실패: \(error.localizedDescription)")
                    
                    observer(.failure(DatabaseError.saveFailed))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // 보고싶은 모든 미디어 불러오기
    func fetchAllMedia() -> Single<[MediaEntity]> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            backgroundContext.perform {
                let request: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                let sortDescriptor = NSSortDescriptor(key: "addedDate", ascending: false)
                request.sortDescriptors = [sortDescriptor]
                
                do {
                    let results = try backgroundContext.fetch(request)
                    observer(.success(results))
                    
                } catch {
                    print("Failed to fetch media: \(error)")
                    observer(.failure(DatabaseError.fetchFailed))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // 보고싶은 Media 삭제
    func deleteMedia(id: Int) -> Single<Void> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            backgroundContext.perform {
                do {
                    let request: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %d", id)
                    
                    if let deleteObject = try backgroundContext.fetch(request).first {
                        let title = deleteObject.title
                        
                        backgroundContext.delete(deleteObject)
                        
                        try backgroundContext.save()
                        
                        print("\(title) 삭제 완료")
                        observer(.success(()))
                    } else {
                        observer(.failure(DatabaseError.deleteFailed))
                    }
                } catch {
                    print("미디어 삭제 실패: \(error.localizedDescription)")
                    observer(.failure(DatabaseError.deleteFailed))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchMedia(id: Int) -> Single<(Bool, NSManagedObjectID?, Bool, Date?, Bool)?> {
        return Single.create { single in
            let context = self.stack.newBackgroundContext()
            context.perform {
                let request: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %d", id)
                request.fetchLimit = 1
                
                do {
                    let results = try context.fetch(request)
                    if let entity = results.first {
                        let result = (true, entity.objectID, entity.isStar, entity.watchedDate, entity.review != nil)
                        single(.success(result))
                    } else {
                        single(.success(nil))
                    }
                } catch {
                    single(.failure(DatabaseError.fetchFailed))
                }
            }
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
    
    func fetchMediaEntity(id: Int) -> Single<MediaEntity?> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                return Disposables.create()
            }
            
            let context = self.stack.viewContext
            context.perform {
                let request: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "id == %d", id)
                do {
                    let entity = try context.fetch(request).first
                    observer(.success(entity))
                } catch {
                    observer(.failure(DatabaseError.fetchFailed))
                }
            }
            return Disposables.create()
        }
    }
    
    func updateWatchedDate(id: Int, watchedDate: Date?) -> Single<NSManagedObjectID> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
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
                        observer(.success((mediaToUpdate.objectID)))
                    } else {
                        observer(.failure(DatabaseError.updateFailed))
                    }
                } catch {
                    print("업데이트 실패: \(error.localizedDescription)")
                    observer(.failure(DatabaseError.updateFailed))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func updateIsStared(id: Int, isStar: Bool) -> Single<Bool> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            
            backgroundContext.perform {
                let request: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %d", id)
                
                do {
                    if let mediaToUpdate = try backgroundContext.fetch(request).first {
                        mediaToUpdate.isStar = isStar
                        try backgroundContext.save()
                        print("\(mediaToUpdate.title) 즐겨찾기 업데이트 완료 = \(isStar)")
                        observer(.success((mediaToUpdate.isStar)))
                    } else {
                        observer(.failure(DatabaseError.updateFailed))
                    }
                } catch {
                    print("업데이트 실패: \(error.localizedDescription)")
                    observer(.failure(DatabaseError.updateFailed))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func updateIsWatchlist(id: Int, isWatchlist: Bool) -> Single<Bool> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            
            backgroundContext.perform {
                let request: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %d", id)
                
                do {
                    if let mediaToUpdate = try backgroundContext.fetch(request).first {
                        mediaToUpdate.addedDate = isWatchlist ? Date() : nil
                        try backgroundContext.save()
                        observer(.success(mediaToUpdate.addedDate != nil))
                    } else {
                        observer(.failure(DatabaseError.updateFailed))
                    }
                } catch {
                    print("업데이트 실패: \(error.localizedDescription)")
                    observer(.failure(DatabaseError.updateFailed))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // 티어 설정
    func updateTier(mediaID: Int, newTier: String?) -> Single<Void> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            
            backgroundContext.perform {
                let request: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %d", mediaID)
                
                do {
                    if let mediaToUpdate = try backgroundContext.fetch(request).first {
                        mediaToUpdate.tier = newTier
                        try backgroundContext.save()
                        print("\(mediaToUpdate.title) 티어 업데이트 완료 -> \(newTier ?? "Unranked")")
                        observer(.success(()))
                    } else {
                        observer(.failure(DatabaseError.updateFailed))
                    }
                } catch {
                    print("티어 업데이트 실패: \(error.localizedDescription)")
                    observer(.failure(DatabaseError.updateFailed))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func updateMediaDetail(id: Int, mediaDetail: MediaDetail) -> Single<Bool> {
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(DatabaseError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            backgroundContext.perform {
                let request: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %d", id)
                
                do {
                    if let mediaToUpdate = try backgroundContext.fetch(request).first {
                        
                        var hasChanges = false
                        
                        if mediaToUpdate.overview != mediaDetail.overview {
                            hasChanges = true
                        }
                        if mediaToUpdate.certificate != mediaDetail.certificate {
                            hasChanges = true
                        }
                        if mediaToUpdate.runtimeOrEpisodeInfo != mediaDetail.runtimeOrEpisodeInfo {
                            hasChanges = true
                        }
                        
                        let oldCastIDs = (mediaToUpdate.casts as? Set<CastEntity>)?.map { $0.id }.sorted() ?? []
                        let newCastIDs = mediaDetail.cast.map { Int64($0.id) }.sorted()
                        if oldCastIDs != newCastIDs {
                            hasChanges = true
                        }
                        
                        let oldCrewIDs = (mediaToUpdate.crews as? Set<CrewEntity>)?.map { $0.id }.sorted() ?? []
                        let newCrewIDs = mediaDetail.creator.map { Int64($0.id) }.sorted()
                        if oldCrewIDs != newCrewIDs {
                            hasChanges = true
                        }
                        
                        guard hasChanges else {
                            print("\(mediaToUpdate.title) 상세 정보 변경점 없음")
                            observer(.success(false))
                            return
                        }
                        
                        mediaToUpdate.overview = mediaDetail.overview
                        mediaToUpdate.certificate = mediaDetail.certificate
                        mediaToUpdate.runtimeOrEpisodeInfo = mediaDetail.runtimeOrEpisodeInfo
                        
                        if let oldCasts = mediaToUpdate.casts {
                            mediaToUpdate.removeFromCasts(oldCasts)
                        }
                        
                        if let oldCrews = mediaToUpdate.crews {
                            mediaToUpdate.removeFromCrews(oldCrews)
                        }
                        
                        for (index, cast) in mediaDetail.cast.enumerated() {
                            let castEntity = CastEntity(context: backgroundContext)
                            castEntity.id = Int64(cast.id)
                            castEntity.name = cast.name
                            castEntity.character = cast.character
                            castEntity.profileURL = cast.profilePath
                            castEntity.index = Int64(index)
                            mediaToUpdate.addToCasts(castEntity)
                        }
                        
                        for (index, crew) in mediaDetail.creator.enumerated() {
                            let crewEntity = CrewEntity(context: backgroundContext)
                            crewEntity.id = Int64(crew.id)
                            crewEntity.name = crew.name
                            crewEntity.department = crew.department
                            crewEntity.profileURL = crew.profilePath
                            crewEntity.index = Int64(index)
                            mediaToUpdate.addToCrews(crewEntity)
                        }
                        
                        try backgroundContext.save()
                        print("\(mediaToUpdate.title) 상세 정보 업데이트 완료")
                        observer(.success(true))
                        
                    } else {
                        observer(.success(false))
                    }
                } catch {
                    print("미디어 상세 정보 업데이트 실패: \(error.localizedDescription)")
                    observer(.failure(DatabaseError.updateFailed))
                }
            }
            
            return Disposables.create()
        }
    }
}
