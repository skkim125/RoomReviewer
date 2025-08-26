//
//  ReviewDatabaseManagerUnitTests.swift
//  ReviewDatabaseManagerUnitTests
//
//  Created by 김상규 on 8/26/25.
//

import XCTest
import RxSwift
import CoreData
@testable import RoomReviewer

final class ReviewDatabaseManagerUnitTests: XCTestCase {
    var mockDataStack: DataStack!
    var sut1: MediaDBManager!
    var sut2: ReviewDBManager!
    var disposeBag: DisposeBag!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockDataStack = MockCoreDataStack()
        sut1 = MediaDatabaseManager(stack: mockDataStack)
        sut2 = ReviewDatabaseManager(stack: mockDataStack)
        disposeBag = DisposeBag()
    }
    
    override func tearDownWithError() throws {
        mockDataStack = nil
        sut1 = nil
        sut2 = nil
        disposeBag = nil
        try super.tearDownWithError()
    }
    
    func test_createReview_Success() {
        let expectation = XCTestExpectation(description: "미디어 생성 후 리뷰 생성 성공")
        
        let testId = 123
        let testTitle = "Test Movie"
        
        let testRating = 4.5
        let testReview = "testReview"
        let testComment = "testComment"
        let testQuote = "testQuote"
        
        sut1.createMedia(id: testId, title: testTitle, overview: "", type: "movie", genres: [], releaseDate: "", watchedDate: nil)
            .flatMap { [weak self] mediaObjectID -> Single<NSManagedObjectID> in
                guard let self = self else {
                    return .error(NSError(domain: "UnitTestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "self is nil"]))
                }
                
                return self.sut2.createReview(mediaObjectID, rating: testRating, review: testReview, comment: testComment, quote: testQuote)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, reviewObjectID in
                XCTAssertNotNil(reviewObjectID)
                
                do {
                    let savedReview = try owner.mockDataStack.viewContext.existingObject(with: reviewObjectID) as? ReviewEntity
                    
                    XCTAssertNotNil(savedReview?.media, "ReviewEntity에 MediaEntity가 연결되지 않았습니다.")
                    XCTAssertEqual(savedReview?.media.id, Int64(testId))
                    XCTAssertEqual(savedReview?.rating, testRating)
                    XCTAssertEqual(savedReview?.review, testReview)
                    XCTAssertEqual(savedReview?.comment, testComment)
                    XCTAssertEqual(savedReview?.quote, testQuote)
                    
                    expectation.fulfill()
                    
                } catch {
                    XCTFail("ID로 Review 객체를 가져오는 데 실패했습니다: \(error)")
                }
            } onFailure: { _, error in
                XCTFail("createMedia 또는 createReview가 실패했습니다: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_fetchAllReview_Success() {
        let expectation = XCTestExpectation(description: "미디어 생성 후 모든 리뷰 불러오기 성공")
        
        let testId = 123
        let testTitle = "Test Movie"
        
        let testRating = 4.5
        let testReview = "testReview"
        let testComment = "testComment"
        let testQuote = "testQuote"
        
        sut1.createMedia(id: testId, title: testTitle, overview: "", type: "movie", genres: [], releaseDate: "", watchedDate: nil)
            .flatMap { [weak self] mediaObjectID -> Single<NSManagedObjectID> in
                guard let self = self else {
                    return .error(NSError(domain: "UnitTestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "self is nil"]))
                }
                
                return self.sut2.createReview(mediaObjectID, rating: testRating, review: testReview, comment: testComment, quote: testQuote)
            }
            .flatMap { [weak self] reviewObjectID -> Single<[ReviewEntity]> in
                guard let self = self else {
                    return .error(NSError(domain: "UnitTestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "self is nil"]))
                }
                
                return self.sut2.fetchAllReview()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, reviews in
                XCTAssertEqual(reviews.count, 1)
                
                expectation.fulfill()
                
            } onFailure: { _, error in
                XCTFail("createMedia 또는 fetchAllReview가 실패했습니다: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_fetchReview_Success() {
        let expectation = XCTestExpectation(description: "미디어 생성 후 리뷰 불러오기 성공")
        
        let testId = 123
        let testTitle = "Test Movie"
        
        let testRating = 4.5
        let testReview = "testReview"
        let testComment = "testComment"
        let testQuote = "testQuote"
        
        sut1.createMedia(id: testId, title: testTitle, overview: "", type: "movie", genres: [], releaseDate: "", watchedDate: nil)
            .flatMap { [weak self] mediaObjectID -> Single<NSManagedObjectID> in
                guard let self = self else {
                    return .error(NSError(domain: "UnitTestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "self is nil"]))
                }
                
                return self.sut2.createReview(mediaObjectID, rating: testRating, review: testReview, comment: testComment, quote: testQuote)
            }
            .flatMap { [weak self] reviewObjectID -> Single<ReviewEntity?> in
                guard let self = self else {
                    return .error(NSError(domain: "UnitTestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "self is nil"]))
                }
                
                return self.sut2.fetchReview(reviewObjectID: reviewObjectID)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, review in
                
                guard let review = review else {
                    XCTFail("ID로 Review 객체를 가져오는 데 실패했습니다")
                    return
                }
                
                do {
                    XCTAssertNotNil(review.media, "ReviewEntity에 MediaEntity가 연결되지 않았습니다.")
                    XCTAssertEqual(review.media.id, Int64(testId))
                    XCTAssertEqual(review.rating, testRating)
                    XCTAssertEqual(review.review, testReview)
                    XCTAssertEqual(review.comment, testComment)
                    XCTAssertEqual(review.quote, testQuote)
                    
                    expectation.fulfill()
                }
                
            } onFailure: { _, error in
                XCTFail("createMedia 또는 fetchReview가 실패했습니다: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_deleteReview_Success() {
        let expectation = XCTestExpectation(description: "미디어 생성 후 리뷰 삭제 성공")
        
        let testId = 123
        let testTitle = "Test Movie"
        
        let testRating = 4.5
        let testReview = "testReview"
        let testComment = "testComment"
        let testQuote = "testQuote"
        
        sut1.createMedia(id: testId, title: testTitle, overview: "", type: "movie", genres: [], releaseDate: "", watchedDate: nil)
            .flatMap { [weak self] mediaObjectID -> Single<NSManagedObjectID> in
                guard let self = self else {
                    return .error(NSError(domain: "UnitTestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "self is nil"]))
                }
                
                return self.sut2.createReview(mediaObjectID, rating: testRating, review: testReview, comment: testComment, quote: testQuote)
            }
            .flatMap { [weak self] reviewObjectID -> Single<Void?> in
                guard let self = self else {
                    return .error(NSError(domain: "UnitTestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "self is nil"]))
                }
                
                return self.sut2.deleteReview(reviewObjectID: reviewObjectID)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, deleted in
                XCTAssertNotNil(deleted)
                
                expectation.fulfill()
                
            } onFailure: { _, error in
                XCTFail("createMedia 또는 deleteReview가 실패했습니다: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 2.0)
    }
}
