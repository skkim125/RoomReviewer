//
//  NetworkTransformMediaDetailTests.swift
//  NetworkTransformMediaDetailTests
//
//  Created by 김상규 on 8/23/25.
//

import XCTest
import ReactorKit

@testable import RoomReviewer

final class NetworkTransformMediaDetailTests: XCTestCase {
    
    var networkManager: NetworkService!
    var disposeBag: DisposeBag!
    
    override func setUpWithError() throws {
        networkManager = NetworkManager()
        disposeBag = DisposeBag()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        networkManager = nil
        disposeBag = nil
    }
    
    func test_fetch_movieDetail() throws {
        let expectation = XCTestExpectation(description: "영화 디테일 불러오기 성공")
        let id = 803796
        let target = TMDBTargetType.getMovieDetail(id)
        networkManager.callRequest(target)
            .asObservable()
            .map { (result: Result<MovieDetail, Error>) -> MovieDetail? in
                switch result {
                case .success(let success):
                    return success
                case .failure(let failure):
                    XCTFail("error: \(failure.localizedDescription)")
                    return nil
                }
            }
            .bind(with: self) { owner, movieDetail in
                guard let movieDetail = movieDetail else {
                    return
                }
                
                XCTAssertEqual(movieDetail.id, id)
                expectation.fulfill()
            }
            .disposed(by: disposeBag)
        
        wait(for: [expectation], timeout: 100.0)
    }
    
    func test_fetch_tvDetail() throws {
        let expectation = XCTestExpectation(description: "tv 디테일 불러오기 성공")
        let id = 231280
        let target = TMDBTargetType.getTVDetail(id)
        networkManager.callRequest(target)
            .asObservable()
            .map { (result: Result<TVDetail, Error>) -> TVDetail? in
                switch result {
                case .success(let success):
                    return success
                case .failure(let failure):
                    XCTFail("error: \(failure.localizedDescription)")
                    return nil
                }
            }
            .bind(with: self) { owner, tvDetail in
                guard let tvDetail = tvDetail else {
                    return
                }
                
                XCTAssertEqual(tvDetail.id, id)
                expectation.fulfill()
            }
            .disposed(by: disposeBag)
        
        wait(for: [expectation])
    }
    
    func test_transform_movieDetail_to_mediaDetail() throws {
        let expectation = XCTestExpectation(description: "영화 디테일 변환 성공")
        let id: Int = 803796
        let target = TMDBTargetType.getMovieDetail(id)
        networkManager.callRequest(target)
            .asObservable()
            .map { (result: Result<MovieDetail, Error>) -> MediaDetail? in
                switch result {
                case .success(let success):
                    return success.toDomain()
                case .failure(let failure):
                    XCTFail("error: \(failure.localizedDescription)")
                    return nil
                }
            }
            .bind(with: self) { owner, mediaDetail in
                guard let mediaDetail = mediaDetail else {
                    return
                }
                
                XCTAssertEqual(mediaDetail.id, id)
                print(mediaDetail.title)
                print(mediaDetail.runtimeOrEpisodeInfo)
                print(mediaDetail.genres)
                print(mediaDetail.certificate)
                print(mediaDetail.cast.count)
                print(mediaDetail.creator)
                expectation.fulfill()
            }
            .disposed(by: disposeBag)
        
        wait(for: [expectation])
    }
    
    func test_transform_tvDetail_to_mediaDetail() throws {
        let expectation = XCTestExpectation(description: "tv 디테일 변환 성공")
        let id: Int = 231280
        let target = TMDBTargetType.getTVDetail(id)
        networkManager.callRequest(target)
            .asObservable()
            .map { (result: Result<TVDetail, Error>) -> MediaDetail? in
                switch result {
                case .success(let success):
                    return success.toDomain()
                case .failure(let failure):
                    XCTFail("error: \(failure.localizedDescription)")
                    return nil
                }
            }
            .bind(with: self) { owner, mediaDetail in
                guard let mediaDetail = mediaDetail else {
                    return
                }
                
                XCTAssertEqual(mediaDetail.id, id)
                print(mediaDetail.title)
                print(mediaDetail.runtimeOrEpisodeInfo)
                print(mediaDetail.genres)
                print(mediaDetail.certificate)
                print(mediaDetail.cast.count)
                print(mediaDetail.creator)
                expectation.fulfill()
            }
            .disposed(by: disposeBag)
        
        wait(for: [expectation])
    }
}
