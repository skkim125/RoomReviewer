//
//  HomeReactorLoadDataUnitTest.swift
//  HomeReactorLoadDataUnitTest
//
//  Created by 김상규 on 6/22/25.
//

//import XCTest
//import RxSwift
//import RxTest
//import RxCocoa
//
//@testable import RoomReviewer
//
//final class HomeReactorLoadDataUnitTest: XCTestCase {
//    var reactor: HomeReactor!
//    var mockNetworkManager: MockNetworkManager!
//    var mockDataStack: DataStack!
//    var mediaDBManager: MediaDBManager!
//    var scheduler: TestScheduler!
//    var disposeBag: DisposeBag!
//    
//    override func setUpWithError() throws {
//        disposeBag = DisposeBag()
//        mockNetworkManager = MockNetworkManager()
//        mockDataStack = MockCoreDataStack()
//        mediaDBManager = MediaDatabaseManager(stack: mockDataStack)
//        scheduler = TestScheduler(initialClock: 0)
//    }
//    
//    override func tearDownWithError() throws {
//        reactor = nil
//        mockNetworkManager = nil
//        disposeBag = nil
//        scheduler = nil
//        
//        try super.tearDownWithError()
//    }
//
//    func test_SuccessLoadData() {
//        let movieResult = movieJsonResult.data(using: .utf8)!
//        let tvResult = tvJsonResult.data(using: .utf8)!
//        mockNetworkManager.mockMovieResult = .success(movieResult)
//        mockNetworkManager.mockTVResult = .success(tvResult)
//        reactor = HomeReactor(networkService: mockNetworkManager, mediaDBManager: mediaDBManager)
//
//        let observer = scheduler.createObserver(HomeReactor.State.self)
//        
//        reactor.state
//            .subscribe(observer)
//            .disposed(by: disposeBag)
//
//        scheduler.createColdObservable([
//            .next(20, HomeReactor.Action.fetchData)
//        ])
//        .bind(to: reactor.action)
//        .disposed(by: disposeBag)
//
//        scheduler.start()
//        
//        let events = observer.events
//        let finalState = events.last?.value.element
//        XCTAssertEqual(finalState?.medias.count, 2)
//        
//        let tvItems = finalState?.medias.first?.items ?? []
//        XCTAssertEqual(tvItems.count, 2)
//    }
//}
//
//extension HomeReactorLoadDataUnitTest {
//    var tvJsonResult: String {
//        """
//        {
//            "results": [
//                {
//                    "id": 227191,
//                    "name": "나인 퍼즐",
//                    "overview": "프로파일러가 된 이나의 미스터리.",
//                    "genre_ids": [80, 9648],
//                    "backdrop_path": "/tv1.jpg",
//                    "poster_path": "/tv1poster.jpg",
//                    "first_air_date": "2025-05-21"
//                },
//                {
//                    "id": 261980,
//                    "name": "미지의 서울",
//                    "overview": "쌍둥이 자매의 로맨스.",
//                    "genre_ids": [35, 18],
//                    "backdrop_path": "/tv2.jpg",
//                    "poster_path": "/tv2poster.jpg",
//                    "first_air_date": "2025-05-24"
//                }
//            ],
//            "total_pages": 1
//        }
//        """
//    }
//
//    var movieJsonResult: String {
//        """
//        {
//            "results": [
//                {
//                    "id": 111,
//                    "title": "서울의 밤",
//                    "overview": "서울의 밤을 배경으로 한 범죄 액션 영화.",
//                    "genre_ids": [28, 80],
//                    "poster_path": "/movie1poster.jpg",
//                    "release_date": "2025-05-10"
//                },
//                {
//                    "id": 112,
//                    "title": "로맨틱 코미디",
//                    "overview": "연애 초보들의 좌충우돌 이야기.",
//                    "genre_ids": [35, 10749],
//                    "poster_path": "/movie2poster.jpg",
//                    "release_date": "2025-04-01"
//                }
//            ],
//            "total_pages": 1
//        }
//        """
//    }
//}
//
