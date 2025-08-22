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
        $0.alignment = .leading
    }
    
    private let titleAndYearLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 20)
        $0.numberOfLines = 0
    }
    
    private let mediaTypeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .gray
    }
    
    private let genreLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .darkGray
        $0.numberOfLines = 0
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
        $0.textColor = .darkGray
    }
    
    private let creditsTitleLabel = UILabel().then {
        $0.text = "주요 출연진"
        $0.font = .boldSystemFont(ofSize: 18)
    }
    
    private let directorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15)
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
    private let disposeBag = DisposeBag()
    
    init(reactor: MediaDetailReactor, imageProvider: ImageProviding) {
        self.reactor = reactor
        self.imageProvider = imageProvider
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
        bindAction(reactor: reactor)
    }
    
    private func bindState(reactor: MediaDetailReactor) {
        
        reactor.state.map { $0.media }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, media in
                owner.mediaTypeLabel.text = media.mediaType.rawValue
                
                let yearString = media.releaseDate.map { String($0.prefix(4)) }
                owner.titleAndYearLabel.attributedText = owner.setTitleStyle(title: media.title, year: yearString)
                
                owner.overviewLabel.text = media.overview
                
                owner.genreLabel.text = API.convertGenreString(media.genreIDS).joined(separator: " / ")
            }
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
                owner.reviewButton.configuration?.baseForegroundColor = isWatchlisted ? .systemRed : .darkGray
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$pushWriteReviewView)
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, flag in
                if let _ = flag {
                    owner.navigationController?.pushViewController(UIViewController(), animated: true)
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
        
        reactor.state.map { $0.director }
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, director in
                if let director = director {
                    owner.directorLabel.text = "연출: \(director.name)"
                    owner.directorLabel.isHidden = false
                } else {
                    owner.directorLabel.isHidden = true
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
            titleText = "보고 싶은 미디어에 저장됨"
            color = .systemBlue
            imageName = "checkmark.circle.fill"
        } else {
            titleText = "보고 싶어요"
            color = .darkGray
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
        [titleAndYearLabel, mediaTypeLabel, genreLabel].forEach {
            infoStackView.addArrangedSubview($0)
        }
        
        contentView.addSubview(actionButtonStackView)
        [watchlistButton, reviewButton].forEach {
            actionButtonStackView.addArrangedSubview($0)
        }
        
        contentView.addSubview(overviewLabel)
        contentView.addSubview(creditsTitleLabel)
        contentView.addSubview(directorLabel)
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
        
        infoStackView.snp.makeConstraints {
            $0.top.equalTo(backDropImageView.snp.bottom).offset(15)
            $0.leading.equalTo(shadowView.snp.trailing).offset(15)
            $0.trailing.equalTo(contentView).inset(20)
        }
        
        actionButtonStackView.snp.makeConstraints {
            $0.top.equalTo(shadowView.snp.bottom).offset(15)
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
        
        directorLabel.snp.makeConstraints {
            $0.top.equalTo(creditsTitleLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalTo(contentView).inset(20)
        }
        
        castCollectionView.snp.makeConstraints {
            $0.top.equalTo(directorLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalTo(contentView).inset(10)
            $0.height.equalTo(220)
            $0.bottom.equalTo(contentView).inset(10)
        }
    }
}

extension MediaDetailViewController {
    func setTitleStyle(title: String, year: String?) -> NSAttributedString {
        let fullText: String
        if let year = year {
            fullText = "\(title) \(year)"
        } else {
            fullText = title
        }
        
        let attributed = NSMutableAttributedString(string: fullText)
        
        if let year = year,
           let range = fullText.range(of: "\(year)") {
            let nsRange = NSRange(range, in: fullText)
            
            attributed.addAttributes([
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ], range: nsRange)
        }
        
        return attributed
    }
    
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
