//
//  CoreDataManager.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/17/25.
//

import Foundation
import CoreData
import RxSwift

protocol DBManager {
    func createMedia(id: String, title: String, type: String, releaseDate: Date?, watchedDate: Date?) -> Single<NSManagedObjectID>
}

final class CoreDataManager: DBManager {
    private let stack: DataStack
    
    init(stack: DataStack) {
        self.stack = stack
    }

    // 보고 싶은 or 리뷰 작성을 위한 Media 생성 & 저장
    func createMedia(id: String, title: String, type: String, releaseDate: Date?, watchedDate: Date?) -> Single<NSManagedObjectID> {
        
        return Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NetworkError.commonError))
                return Disposables.create()
            }
            
            let backgroundContext = self.stack.newBackgroundContext()
            
            backgroundContext.perform {
                let media = MediaEntity(context: backgroundContext)
                media.id = id
                media.title = title
                media.type = type
                media.releaseDate = releaseDate
                media.watchedDate = watchedDate
                media.addedDate = Date()
                
                do {
                    try backgroundContext.save()
                    print("\(media.title ?? "") 저장 완료")
                    
                    observer(.success(media.objectID))
                } catch {
                    print("저장 실패: \(error.localizedDescription)")
                    
                    observer(.failure(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // 보고싶은 모든 미디어 불러오기
//    func fetchAllMedia() -> [MediaEntity] {
//
//    }
    
    // 보고싶은 Media 삭제
//    func deleteMedia(_ media: MediaEntity) {
//
//    }

    // Review 생성
//    func createReview(_ media: MediaEntity, rate: Double, viewingDate: Date, text: String?) -> ReviewEntity {
//
//    }
    
    // Review 삭제
//    func deleteReview(_ media: MediaEntity) {
//
//    }
}
