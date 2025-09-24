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
    var reactor: TrendMediaCollectionViewCellReactor!
    var mockImageProvider: MockImageProvider!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    override func setUpWithError() throws {
        mockImageProvider = MockImageProvider()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }
    
    override func tearDownWithError() throws {
        reactor = nil
        mockImageProvider = nil
        disposeBag = nil
        scheduler = nil
        
        try super.tearDownWithError()
    }
    
    func test_SuccessLoadImage() {
        let tv = Media.mockTV
        
        reactor = TrendMediaCollectionViewCellReactor(media: tv, imageProvider: mockImageProvider)
        
        guard let image = UIImage(systemName: "star.fill"), let testImage = image.pngData() else {
            XCTFail("이미지 변환 실패")
            return
        }
        mockImageProvider.returnedImageData = testImage
        
        let observer = scheduler.createObserver(TrendMediaCollectionViewCellReactor.State.self)
        reactor.state
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        scheduler.createColdObservable([
            .next(20, TrendMediaCollectionViewCellReactor.Action.loadImage)
        ])
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertNotNil(mockImageProvider.returnedImageData)
        
        let events = observer.events
        XCTAssertTrue(events.count >= 4)
        
        let loadSuccess = events.first { $0.value.element?.isLoading == true }?.value.element
        XCTAssertNotNil(loadSuccess)
        XCTAssertTrue(loadSuccess!.isLoading)
        
        let reactorImage = events.first { $0.value.element?.imageData != nil }?.value.element
        XCTAssertNotNil(reactorImage)
        XCTAssertNotNil(reactorImage!.imageData)
        
        let loadFail = events.last?.value.element
        XCTAssertNotNil(loadFail)
        XCTAssertFalse(loadFail!.isLoading)
    }
    
    func test_LoadImageWithNilURL() {
        let tv = Media.mockTVwithNilPosterURL
        reactor = TrendMediaCollectionViewCellReactor(media: tv, imageProvider: mockImageProvider)
        
        let observer = scheduler.createObserver(TrendMediaCollectionViewCellReactor.State.self)
        reactor.state
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        scheduler.createColdObservable([
            .next(10, TrendMediaCollectionViewCellReactor.Action.loadImage)
        ])
        .bind(to: reactor.action)
        .disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(mockImageProvider.returnedImageData?.count, 0)
        
        let events = observer.events
        let finalState = events.last?.value.element
        XCTAssertNotNil(finalState)
        XCTAssertEqual(finalState!.isLoading, false)
        XCTAssertEqual(finalState?.imageData, UIImage(systemName: "photo.fill"))
    }
}

final class MockImageProvider: ImageProviding {
    var fetchImageCallCount = 0
    var returnedImageData: Data?

    func fetchImage(urlString: String?) -> Observable<Data?> {
        fetchImageCallCount += 1
        return .just(returnedImageData)
    }
}
