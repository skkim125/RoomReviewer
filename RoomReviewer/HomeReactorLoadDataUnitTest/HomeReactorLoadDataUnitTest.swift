//
//  HomeReactorLoadDataUnitTest.swift
//  HomeReactorLoadDataUnitTest
//
//  Created by 김상규 on 6/22/25.
//

import XCTest
import RxSwift
import RxTest
import RxCocoa
import ReactorKit
@testable import RoomReviewer

final class HomeReactorLoadDataUnitTest: XCTestCase {
    var reactor: HomeReactor!
    var mockNetworkManager: MockNetworkManager!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    override func setUpWithError() throws {
        disposeBag = DisposeBag()
        mockNetworkManager = MockNetworkManager()
        scheduler = TestScheduler(initialClock: 0)
    }
    
    override func tearDownWithError() throws {
        reactor = nil
        mockNetworkManager = nil
        disposeBag = nil
        scheduler = nil
        
        try super.tearDownWithError()
    }

    func test_SuccessLoadData() {
        let jsonData = jsonResult.data(using: .utf8)!
        mockNetworkManager.mockResult = .success(jsonData)
        reactor = HomeReactor(networkService: mockNetworkManager)

        let observer = scheduler.createObserver(HomeReactor.State.self)
        
        reactor.state
            .subscribe(observer)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([
            .next(20, HomeReactor.Action.fetchData)
        ])
        .bind(to: reactor.action)
        .disposed(by: disposeBag)

        scheduler.start()
        
        let events = observer.events
        let finalState = events.last?.value.element
        XCTAssertEqual(finalState?.medias.count, 1)
        
        let tvItems = finalState?.medias.first?.items ?? []
        XCTAssertEqual(tvItems.count, 2)
    }
}

extension HomeReactorLoadDataUnitTest {
    var jsonResult: String {
          """
              {
                  "results": [
                        {
                          "adult": false,
                          "backdrop_path": "/tJSAxxjCtbtZYMBQkfxvdgqXsz5.jpg",
                          "genre_ids": [
                              80,
                              9648,
                              18
                          ],
                          "id": 227191,
                          "origin_country": [
                              "KR"
                          ],
                          "original_language": "ko",
                          "original_name": "나인 퍼즐",
                          "overview": "삼촌 죽음의 유일한 목격자인 이나는 사건의 진실을 밝히기 위해 프로파일러가 된다. 강력팀 형사 한샘은 그런 이나를 용의자로 집요하게 의심하고, 10년 만에 도착한 의문의 퍼즐과 함께 살인이 다시 시작된다. 이나와 한샘은 퍼즐 연쇄살인을 막을 수 있을까?",
                          "popularity": 51.3198,
                          "poster_path": "/p5q5tS8PVdZiWaUNdeYPHrOMcaI.jpg",
                          "first_air_date": "2025-05-21",
                          "name": "나인 퍼즐",
                          "vote_average": 7.2,
                          "vote_count": 17
                      },
                      {
                          "adult": false,
                          "backdrop_path": "/m0VuPoWQhbgMjVIwAdZmmHgHQrl.jpg",
                          "genre_ids": [
                              35,
                              18
                          ],
                          "id": 261980,
                          "origin_country": [
                              "KR"
                          ],
                          "original_language": "ko",
                          "original_name": "미지의 서울",
                          "overview": "얼굴 빼고 모든 게 다른 쌍둥이 자매가 인생을 맞바꾸는 거짓말로 진짜 사랑과 인생을 찾아가는 로맨틱 성장 드라마",
                          "popularity": 24.141,
                          "poster_path": "/woGYRE5vChxqUqTBJJaOhO9Cqk6.jpg",
                          "first_air_date": "2025-05-24",
                          "name": "미지의 서울",
                          "vote_average": 7.444,
                          "vote_count": 9
                      }
                  ]
              }
              """
    }
}
