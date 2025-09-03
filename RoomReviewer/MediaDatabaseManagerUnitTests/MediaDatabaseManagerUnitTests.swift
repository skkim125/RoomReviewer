//
//  CoreDataManagerUnitTests.swift
//  CoreDataManagerUnitTests
//
//  Created by 김상규 on 8/17/25.
//

import XCTest
import RxSwift
import CoreData
@testable import RoomReviewer

final class MediaDatabaseManagerUnitTests: XCTestCase {
    var mockDataStack: DataStack!
    var sut: MediaDBManager!
    var disposeBag: DisposeBag!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockDataStack = MockCoreDataStack()
        sut = MediaDatabaseManager(stack: mockDataStack)
        disposeBag = DisposeBag()
    }
    
    override func tearDownWithError() throws {
        mockDataStack = nil
        sut = nil
        disposeBag = nil
        try super.tearDownWithError()
    }
    
    func test_createMedia_Success() {
        let expectation = XCTestExpectation(description: "미디어 생성 성공")
        
        let testId = 123
        let testTitle = "Test Movie"
        
        sut.createMedia(id: testId, title: testTitle, overview: "", type: "movie", posterURL: nil, backdropURL: nil, genres: [], releaseDate: "", watchedDate: nil)
            .observe(on: MainScheduler.instance)
            .subscribe { objectID in
                XCTAssertNotNil(objectID)
                do {
                    let savedObject = try self.mockDataStack.viewContext.existingObject(with: objectID) as? MediaEntity
                    XCTAssertEqual(savedObject?.id, Int64(testId))
                    XCTAssertEqual(savedObject?.title, testTitle)
                } catch {
                    XCTFail("ID로 객체를 가져오는 데 실패했습니다: \(error)")
                }
                
                expectation.fulfill()
            } onFailure: { error in
                XCTFail("createMedia가 실패했습니다: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)
    
        wait(for: [expectation], timeout: 1.0)

    }
    
    func test_fetchAllMedia_Success() {
        let expectation = XCTestExpectation(description: "미디어 생성 & 모든 미디어 불러오기 성공")
        
        let testId = 123
        let testTitle = "Test Movie"
        
        sut.createMedia(id: testId, title: testTitle, overview: "", type: "movie", posterURL: nil, backdropURL: nil, genres: [], releaseDate: "", watchedDate: nil)
            .flatMap { [weak self] createdObjectID -> Single<[MediaEntity]> in
                XCTAssertNotNil(createdObjectID)
                
                guard let self = self else {
                    XCTFail("실패")
                    return .just([])
                }
                
                return self.sut.fetchAllMedia()
            }
            .map { $0.map { $0.toDomain() } }
            .observe(on: MainScheduler.instance)
            .subscribe { list in
                XCTAssertEqual(list.count, 1)
                
                guard let firstMedia = list.first else {
                    XCTFail("미디어 리스트가 비어있습니다.")
                    return
                }
                
                XCTAssertEqual(firstMedia.id, testId)
                XCTAssertEqual(firstMedia.title, testTitle)
                
                expectation.fulfill()
                
            } onFailure: { error in
                XCTFail("createMedia 또는 fetchAllMedia가 실패했습니다: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_deleteMedia_Success() {
        let expectation = XCTestExpectation(description: "미디어 삭제 성공")
        
        let testId = 123
        let testTitle = "Test Movie"
        
        sut.createMedia(id: testId, title: testTitle, overview: "", type: "movie", posterURL: nil, backdropURL: nil, genres: [], releaseDate: "", watchedDate: nil)
            .flatMap { [weak self] createdObjectID -> Single<Void?> in
                XCTAssertNotNil(createdObjectID)
                
                guard let self = self else {
                    XCTFail("실패")
                    return .just(nil)
                }
                
                return self.sut.deleteMedia(id: testId)
            }
            .flatMap { [weak self] result -> Single<[MediaEntity]> in
                guard let self = self else {
                    XCTFail("실패")
                    return .just([])
                }
                
                return self.sut.fetchAllMedia()
            }
            .observe(on: MainScheduler.instance)
            .map { $0.map { $0.toDomain() } }
            .subscribe { list in
                XCTAssertEqual(list.count, 0)
                expectation.fulfill()
                
            } onFailure: { error in
                XCTFail("deleteMedia가 실패했습니다: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_updateWatchedDate_Success() {
        let expectation = XCTestExpectation(description: "미디어 시청 날짜 업데이트 성공")
        
        let testId = 123
        let testTitle = "Test Movie"
        let watchedDate = Date()
        
        sut.createMedia(id: testId, title: testTitle, overview: "", type: "movie", posterURL: nil, backdropURL: nil, genres: [], releaseDate: "", watchedDate: nil)
            .flatMap { [weak self] createdObjectID -> Single<NSManagedObjectID?> in
                XCTAssertNotNil(createdObjectID)
                
                guard let self = self else {
                    XCTFail("실패")
                    return .just(nil)
                }
                
                return self.sut.updateWatchedDate(id: testId, watchedDate: watchedDate)
            }
            .flatMap { [weak self] _ -> Single<[MediaEntity]> in
                guard let self = self else {
                    XCTFail("실패")
                    return .just([])
                }
                
                return self.sut.fetchAllMedia()
            }
            .map { $0.map { $0.toDomain() } }
            .observe(on: MainScheduler.instance)
            .subscribe { list in
                XCTAssertEqual(list.count, 1)
                let data = list[0]
                XCTAssert(data.watchedDate == watchedDate)
                expectation.fulfill()
                
            } onFailure: { error in
                XCTFail("updateWatchedDate가 실패했습니다: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 2.0)
    }
}
