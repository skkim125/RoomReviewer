//
//  HomeTVCollectionViewCellReactorTests.swift
//  HomeTVCollectionViewCellReactorTests
//
//  Created by 김상규 on 6/17/25.
//

import XCTest
import RxSwift
import RxTest
import RxCocoa
import ReactorKit
@testable import RoomReviewer

final class HomeTVCollectionViewCellReactorTests: XCTestCase {
    var reactor: HomeTVCollectionViewCellReactor!
    var mockImageLoader: MockImageLoadService!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    override func setUpWithError() throws {
        mockImageLoader = MockImageLoadService()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }
    
    override func tearDownWithError() throws {
        reactor = nil
        mockImageLoader = nil
        disposeBag = nil
        scheduler = nil
        
        try super.tearDownWithError()
    }
    
    func test_SuccessLoadImage() {
        let tv = TV.mockTV
        
        reactor = HomeTVCollectionViewCellReactor(tv: tv, imageLoader: mockImageLoader)
        
        guard let image = UIImage(systemName: "star.fill"), let testImage = image.pngData() else {
            XCTFail("이미지 변환 실패")
            return
        }
        mockImageLoader.loadImageResult = .success(testImage)
        
        let observer = scheduler.createObserver(HomeTVCollectionViewCellReactor.State.self)
        reactor.state
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        scheduler.createColdObservable([
            .next(20, HomeTVCollectionViewCellReactor.Action.loadImage)
        ])
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(mockImageLoader.loadImageCallCount, 1)
        
        let events = observer.events
        XCTAssertTrue(events.count >= 4)
        
        let loadSuccess = events.first { $0.value.element?.isLoading == true }?.value.element
        XCTAssertNotNil(loadSuccess)
        XCTAssertTrue(loadSuccess!.isLoading)
        
        let reactorImage = events.first { $0.value.element?.image != nil }?.value.element
        XCTAssertNotNil(reactorImage)
        XCTAssertNotNil(reactorImage!.image)
        
        let loadFail = events.last?.value.element
        XCTAssertNotNil(loadFail)
        XCTAssertFalse(loadFail!.isLoading)
    }
    
    func test_LoadImageWithNilURL() {
        let tv = TV.mockTVwithNilPosterURL
        reactor = HomeTVCollectionViewCellReactor(tv: tv, imageLoader: mockImageLoader)
        
        let observer = scheduler.createObserver(HomeTVCollectionViewCellReactor.State.self)
        reactor.state
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        scheduler.createColdObservable([
            .next(10, HomeTVCollectionViewCellReactor.Action.loadImage)
        ])
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(mockImageLoader.loadImageCallCount, 0)
        
        let events = observer.events
        let finalState = events.last?.value.element
        XCTAssertNotNil(finalState)
        XCTAssertEqual(finalState!.isLoading, false)
        XCTAssertEqual(finalState?.image, UIImage(systemName: "photo.fill"))
    }
}
