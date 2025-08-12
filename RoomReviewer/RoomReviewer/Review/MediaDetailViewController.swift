//
//  MediaDetailViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/13/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then

final class MediaDetailViewController: UIViewController {
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }
    
    private let contentView = UIView()
    
    private let backDropImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    
    private let shadowView = UIView().then {
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.8
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
        $0.backgroundColor = .clear
    }
    
    private let posterImageView = UIImageView().then {
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 18)
        $0.numberOfLines = 0
    }
    
    private let overviewLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.numberOfLines = 0
        $0.textColor = .darkGray
    }
    
//    private let creditsLabel = UILabel().then {
//        $0.backgroundColor = .systemGray6
//    }
    
    private let reactor: MediaDetailReactor
    private let disposeBag = DisposeBag()
    
    init(reactor: MediaDetailReactor) {
        self.reactor = reactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        configureHierarchy()
        configureLayout()
        bind()
        
        reactor.action.onNext(.viewDidLoad)
    }
    
    private func bind() {
        bindState(reactor: reactor)
    }
    
    private func bindState(reactor: MediaDetailReactor) {
        reactor.state.compactMap { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, isLoading in
                if isLoading {
                    print("로드중")
                } else {
                    print("로드 완료")
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.mediaDetail }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, detail in
                owner.titleLabel.text = detail.mediaInfo.title
                owner.overviewLabel.text = detail.mediaInfo.overview
            }
            .disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.backDropImage }
            .observe(on: MainScheduler.instance)
            .bind(to: backDropImageView.rx.image)
            .disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.posterImage }
            .observe(on: MainScheduler.instance)
            .bind(to: posterImageView.rx.image)
            .disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.errorType }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, error in
                print("로드 에러: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)
    }
}

extension MediaDetailViewController {
    private func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(backDropImageView)
        contentView.addSubview(shadowView)
        shadowView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(overviewLabel)
//        contentView.addSubview(creditsLabel)
    }
    
    private func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.top.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView)
            $0.width.equalTo(scrollView)
        }
        
        backDropImageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalTo(contentView)
            $0.height.equalTo(200)
        }
        
        shadowView.snp.makeConstraints {
            $0.top.equalTo(backDropImageView.snp.bottom).inset(50)
            $0.leading.equalTo(contentView).offset(20)
            $0.width.equalTo(view.bounds.width/3)
            $0.height.equalTo(180)
        }
        
        posterImageView.snp.makeConstraints {
            $0.edges.equalTo(shadowView)
        }
        
        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(posterImageView.snp.centerY)
            $0.leading.equalTo(posterImageView.snp.trailing).offset(15)
            $0.trailing.equalTo(contentView).inset(20)
        }
        
        overviewLabel.snp.makeConstraints {
            $0.top.equalTo(posterImageView.snp.bottom).offset(20)
            $0.horizontalEdges.equalTo(contentView).inset(20)
        }
        
//        creditsLabel.snp.makeConstraints {
//            $0.top.equalTo(overviewLabel.snp.bottom).offset(10)
//            $0.horizontalEdges.equalTo(contentView).inset(20)
//            $0.height.equalTo(800)
//            $0.bottom.equalTo(contentView).inset(10)
//        }
    }
}
