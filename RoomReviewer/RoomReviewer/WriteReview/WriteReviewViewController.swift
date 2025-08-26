//
//  WriteReviewViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/25/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import Cosmos
import SnapKit
import Then

final class WriteReviewViewController: UIViewController, View {
    var disposeBag = DisposeBag()

    private let scrollView = UIScrollView()
    
    private let contentView = UIView()
    
    private let posterImageView = UIImageView().then {
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = .systemGray5
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 22)
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    
    private let ratingSectionTitle = UILabel().then {
        $0.text = "별점 매기기"
        $0.font = .boldSystemFont(ofSize: 18)
    }
    private let ratingView = CosmosView().then {
        var setting = CosmosSettings()
        setting.fillMode = .half
        setting.totalStars = 5
        setting.starSize = 40
        setting.minTouchRating = 0
        setting.starMargin = 5
        setting.emptyBorderWidth = 2
        setting.filledBorderWidth = 2
        setting.emptyBorderColor = .systemYellow
        setting.filledBorderColor = .systemYellow
        setting.filledColor = .systemYellow
        
        $0.settings = setting
        $0.rating = 0
    }
    
    private let reviewTitleLabel = UILabel().then {
        $0.text = "한줄평 작성하기"
        $0.font = .boldSystemFont(ofSize: 18)
    }
    private let reviewTextField = UITextField().then {
        $0.font = .systemFont(ofSize: 14)
        $0.backgroundColor = .secondarySystemBackground
        $0.layer.cornerRadius = 8
    }
    
    private let reviewDetailTitleLabel = UILabel().then {
        $0.text = "상세한 코멘트 남기기"
        $0.font = .boldSystemFont(ofSize: 18)
    }
    private let reviewDetailTextView = UITextView().then {
        $0.font = .systemFont(ofSize: 14)
        $0.backgroundColor = .secondarySystemBackground
        $0.layer.cornerRadius = 8
        $0.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    private let quoteTitleaLabel = UILabel().then {
        $0.text = "내가 꼽은 명대사"
        $0.font = .boldSystemFont(ofSize: 18)
    }
    private let quoteTitleTextView = UITextView().then {
        $0.font = .systemFont(ofSize: 14)
        $0.backgroundColor = .secondarySystemBackground
        $0.layer.cornerRadius = 8
        $0.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    private let saveButton = UIButton(type: .system).then {
        $0.setTitle("내 서재에 저장", for: .normal)
        $0.titleLabel?.font = .boldSystemFont(ofSize: 18)
        $0.backgroundColor = .systemRed
        $0.setTitleColor(.white, for: .normal)
        $0.setTitleColor(.lightGray, for: .disabled)
        $0.layer.cornerRadius = 12
        $0.isEnabled = false
    }
    
    init(reactor: WriteReviewReactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        self.title = "감상 기록하기"
        
        configureHierarchy()
        configureLayout()
        reactor?.action.onNext(.viewDidLoad)
    }
    
    func bind(reactor: WriteReviewReactor) {
        
        reactor.state.map { $0.media.title }
            .asDriver(onErrorJustReturn: nil)
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
         reactor.state.map { $0.posterImage }
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, image in
                if let image = image {
                    owner.posterImageView.image = image
                } else {
                    owner.posterImageView.backgroundColor = .systemGray5
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.canSave }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(with: self) { owner, canSave in
                owner.saveButton.isEnabled = canSave
                owner.saveButton.backgroundColor = canSave ? .systemRed : .darkGray
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$shouldDismiss)
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: ())
            .drive(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        reviewTextField.rx.text.orEmpty
            .bind(with: self) { owner, text in
                print(text.count)
            }
            .disposed(by: disposeBag)
    }
}


extension WriteReviewViewController {
    private func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        
        contentView.addSubview(ratingSectionTitle)
        contentView.addSubview(ratingView)
        
        contentView.addSubview(reviewTitleLabel)
        contentView.addSubview(reviewTextField)
        
        contentView.addSubview(reviewDetailTitleLabel)
        contentView.addSubview(reviewDetailTextView)
        
        contentView.addSubview(quoteTitleaLabel)
        contentView.addSubview(quoteTitleTextView)
        
        view.addSubview(saveButton)
    }
    
    private func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.top.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView)
            $0.width.equalTo(scrollView)
        }
        
        posterImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(view.bounds.width/3)
            $0.height.equalTo(180)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(posterImageView.snp.bottom).offset(15)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        ratingSectionTitle.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        ratingView.snp.makeConstraints {
            $0.top.equalTo(ratingSectionTitle.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }
        
        reviewTitleLabel.snp.makeConstraints {
            $0.top.equalTo(ratingView.snp.bottom).offset(25)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        reviewTextField.snp.makeConstraints {
            $0.top.equalTo(reviewTitleLabel.snp.bottom).offset(15)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(37)
        }
        
        reviewDetailTitleLabel.snp.makeConstraints {
            $0.top.equalTo(reviewTextField.snp.bottom).offset(25)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        reviewDetailTextView.snp.makeConstraints {
            $0.top.equalTo(reviewDetailTitleLabel.snp.bottom).offset(15)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(100)
        }
        
        quoteTitleaLabel.snp.makeConstraints {
            $0.top.equalTo(reviewDetailTextView.snp.bottom).offset(25)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        quoteTitleTextView.snp.makeConstraints {
            $0.top.equalTo(quoteTitleaLabel.snp.bottom).offset(15)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(100)
            $0.bottom.equalTo(contentView.snp.bottom).inset(20)
        }
        
        saveButton.snp.makeConstraints {
            $0.top.equalTo(scrollView.snp.bottom).offset(10)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
            $0.height.equalTo(50)
        }
    }
}
