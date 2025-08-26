//
//  MediaDetailViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/13/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit
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
    
    private let infoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 6
        $0.alignment = .center
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 20)
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    
    private let semiInfoLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .lightGray
        $0.textAlignment = .center
    }
    
    private let mediaTypeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .gray
        $0.textAlignment = .center
    }
    
    private let genreLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .lightGray
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    
    private let actionButtonStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.spacing = 8
    }

    private let watchlistButton = UIButton()
    
    private let reviewButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        
        config.image = UIImage(systemName: "sunglasses")
        config.preferredSymbolConfigurationForImage = .init(pointSize: 20)
        
        config.title = "평론하기"
        config.attributedTitle?.font = .systemFont(ofSize: 12, weight: .semibold)
        config.imagePlacement = .top
        config.imagePadding = 8
        
        
        config.baseForegroundColor = .systemRed
        
        $0.configuration = config
    }
    
    private let overviewLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.numberOfLines = 0
        $0.textColor = .lightGray
        $0.textAlignment = .center
    }
    
    private let creditsTitleLabel = UILabel().then {
        $0.text = "주요 출연진"
        $0.textColor = .white
        $0.font = .boldSystemFont(ofSize: 18)
    }
    
    private let creatorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .white
    }
    
    private lazy var castCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .creditsCollectionViewLayout()).then {
        $0.showsHorizontalScrollIndicator = false
        $0.register(CreditsCollectionViewCell.self, forCellWithReuseIdentifier: CreditsCollectionViewCell.cellID)
        $0.backgroundColor = .gray.withAlphaComponent(0.1)
        $0.showsVerticalScrollIndicator = false
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 12
    }
    
    private let reactor: MediaDetailReactor
    private let imageProvider: ImageProviding
    private let dbManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    private let disposeBag = DisposeBag()
    
    init(reactor: MediaDetailReactor, imageProvider: ImageProviding, dbManager: MediaDBManager, reviewDBManager: ReviewDBManager) {
        self.reactor = reactor
        self.imageProvider = imageProvider
        self.dbManager = dbManager
        self.reviewDBManager = reviewDBManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        configureHierarchy()
        configureLayout()
        setupPlaceholderState()
        bind()
        
        reactor.action.onNext(.viewDidLoad)
    }
    
    private func bind() {
        bindState(reactor: reactor)
        bindAction(reactor: reactor)
    }
    
    private func bindState(reactor: MediaDetailReactor) {
        
        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .compactMap { $0 }
            .filter { !$0 }
            .asDriver(onErrorJustReturn: false)
            .drive(with: self) { owner, isLoading in
                owner.removePlaceholderState()
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.genres }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(genreLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.overview }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(overviewLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.title }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.mediaSemiInfo }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(semiInfoLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.backDropImageData }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, image in
                if let image = image {
                    owner.backDropImageView.image = image
                } else {
                    owner.backDropImageView.backgroundColor = .systemGray6
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.posterImageData }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, image in
                if let image = image {
                    owner.posterImageView.image = image
                } else {
                    owner.posterImageView.backgroundColor = .systemGray6
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.errorType }
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, error in
                guard let error = error else { return }
                print("로드 에러: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.isWatchlisted }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(with: self) { owner, isWatchlisted in
                owner.updateWatchlistButton(isWatchlisted: isWatchlisted)
                owner.reviewButton.configuration?.baseForegroundColor = isWatchlisted ? .systemRed : .lightGray
                owner.reviewButton.isEnabled = isWatchlisted
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$pushWriteReviewView)
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, media in
                if let media = media {
                    let reactor = WriteReviewReactor(media: media, dbManager: owner.dbManager, imageProvider: owner.imageProvider, reviewDBManager: owner.reviewDBManager)
                    let vc = WriteReviewViewController(reactor: reactor)
                    owner.navigationController?.pushViewController(vc, animated: true)
                }
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$showSetWatchedDateAlert)
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, flag in
                if let _ = flag {
                    owner.presentCalendarAlert()
                }
            }
            .disposed(by: disposeBag)

        reactor.state.compactMap { $0.casts }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .map { casts in
                return casts.map { cast in
                    CreditsCollectionViewCellReactor(cast: cast, imageLoader: self.imageProvider)
                }
            }
            .drive(castCollectionView.rx.items(cellIdentifier: CreditsCollectionViewCell.cellID, cellType: CreditsCollectionViewCell.self)) { index, reactor, cell in
                cell.configureCell(reactor: reactor)
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.creatorInfo }
            .asDriver(onErrorJustReturn: (nil, nil))
            .drive(with: self) { owner, creator in
                let (mediaType, creator) = creator
                let creatorTypeText: String
                if let creator = creator {
                    let creatorsText = creator.map { $0.name }.joined(separator: ", ")
                    creatorTypeText = mediaType == .movie ? "감독" : "제작진"
                    owner.creatorLabel.text = "\(creatorTypeText): \(creatorsText)"
                    owner.creatorLabel.isHidden = false
                } else {
                    owner.creatorLabel.isHidden = true
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func bindAction(reactor: MediaDetailReactor) {
        watchlistButton.rx.tap
            .map { MediaDetailReactor.Action.watchlistButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reviewButton.rx.tap
            .map { MediaDetailReactor.Action.writeReviewButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func updateWatchlistButton(isWatchlisted: Bool) {
        var config = UIButton.Configuration.plain()

        config.preferredSymbolConfigurationForImage = .init(pointSize: 20)
        config.imagePlacement = .top
        config.imagePadding = 8

        let titleText: String
        let color: UIColor
        let imageName: String

        if isWatchlisted {
            titleText = "저장됨"
            color = .systemBlue
            imageName = "checkmark.circle.fill"
        } else {
            titleText = "보고 싶어요"
            color = .lightGray
            imageName = "plus.circle"
        }

        config.image = UIImage(systemName: imageName)
        config.baseForegroundColor = color

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let nsAttr = NSAttributedString(
            string: titleText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .paragraphStyle: paragraphStyle
            ]
        )

        if let attr = try? AttributedString(nsAttr, including: \.uiKit) {
            config.attributedTitle = attr
        }

        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                self.watchlistButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.watchlistButton.alpha = 0.0
            }, completion: { _ in
                self.watchlistButton.configuration = config
                
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
                    self.watchlistButton.transform = .identity
                    self.watchlistButton.alpha = 1.0
                })
            })
        }
    }
}

extension MediaDetailViewController {
    private func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(backDropImageView)
        contentView.addSubview(shadowView)
        shadowView.addSubview(posterImageView)
        
        contentView.addSubview(infoStackView)
        [titleLabel, genreLabel, semiInfoLabel].forEach {
            infoStackView.addArrangedSubview($0)
        }
        
        contentView.addSubview(actionButtonStackView)
        [watchlistButton, reviewButton].forEach {
            actionButtonStackView.addArrangedSubview($0)
        }
        
        contentView.addSubview(overviewLabel)
        contentView.addSubview(creditsTitleLabel)
        contentView.addSubview(creatorLabel)
        contentView.addSubview(castCollectionView)
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
            $0.top.equalTo(contentView.snp.top)
            $0.horizontalEdges.equalTo(contentView)
            $0.height.equalTo(280)
            $0.centerX.equalTo(contentView)
        }
        
        shadowView.snp.makeConstraints {
            $0.centerY.equalTo(backDropImageView.snp.bottom).inset(20)
            $0.centerX.equalTo(contentView)
            $0.width.equalTo(view.bounds.width/3)
            $0.height.equalTo(180)
        }
        
        posterImageView.snp.makeConstraints {
            $0.edges.equalTo(shadowView)
        }
        
        infoStackView.snp.makeConstraints {
            $0.top.equalTo(shadowView.snp.bottom).offset(15)
            $0.horizontalEdges.equalTo(contentView).inset(20)
        }
        
        actionButtonStackView.snp.makeConstraints {
            $0.top.equalTo(infoStackView.snp.bottom).offset(15)
            $0.horizontalEdges.equalTo(contentView).inset(20)
        }
        
        overviewLabel.snp.makeConstraints {
            $0.top.equalTo(actionButtonStackView.snp.bottom).offset(15)
            $0.horizontalEdges.equalTo(contentView).inset(20)
        }
        
        creditsTitleLabel.snp.makeConstraints {
            $0.top.equalTo(overviewLabel.snp.bottom).offset(20)
            $0.leading.equalTo(contentView).inset(20)
        }
        
        creatorLabel.snp.makeConstraints {
            $0.top.equalTo(creditsTitleLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalTo(contentView).inset(20)
        }
        
        castCollectionView.snp.makeConstraints {
            $0.top.equalTo(creatorLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalTo(contentView).inset(10)
            $0.height.equalTo(205)
            $0.bottom.equalTo(contentView).inset(10)
        }
    }
}

extension MediaDetailViewController {
    private func presentCalendarAlert() {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.locale = Locale(identifier: "ko-KR")
        datePicker.maximumDate = Date()
        
        let alert = CustomAlertViewController(title: "시청한 날짜 선택", subtitle: "미디어를 시청한 날짜를 선택해주세요.", buttonType: .twoButton, contentView: datePicker) { [weak self] in
            let selectedDate = datePicker.date
            self?.reactor.action.onNext(.updateWatchedDate(selectedDate))
        }
        
        present(alert, animated: true)
    }
    
    private func setupPlaceholderState() {
        backDropImageView.backgroundColor = .systemGray6
        posterImageView.backgroundColor = .systemGray6
        
        let placeholderColor = UIColor.systemGray5
        
        [genreLabel, semiInfoLabel, creatorLabel].forEach {
            $0.text = "\n"
            $0.backgroundColor = placeholderColor
            $0.textColor = .clear
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 8
        }
        
        overviewLabel.text = "\n\n\n"
        overviewLabel.backgroundColor = placeholderColor
        overviewLabel.textColor = .clear
        overviewLabel.clipsToBounds = true
        overviewLabel.layer.cornerRadius = 8
        
        castCollectionView.backgroundColor = .systemGray6
    }
    
    private func removePlaceholderState() {
        [genreLabel, semiInfoLabel, creatorLabel, overviewLabel].forEach {
            $0.backgroundColor = .clear
            $0.textColor = .white
        }
        
        genreLabel.textColor = .lightGray
        semiInfoLabel.textColor = .lightGray
        overviewLabel.textColor = .lightGray
        creatorLabel.textColor = .white
        
        castCollectionView.backgroundColor = .gray.withAlphaComponent(0.1)
    }
}

extension UICollectionViewLayout {
    static func creditsCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0/3),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(180))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(10)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        
        section.orthogonalScrollingBehavior = .continuous
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}
