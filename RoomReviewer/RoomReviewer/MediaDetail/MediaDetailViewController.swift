//
//  MediaDetailViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/13/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import ReactorKit
import SnapKit
import Then

final class MediaDetailViewController: UIViewController, View {
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
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.layer.borderWidth = 0.3
        $0.layer.borderColor = AppColor.appPrimaryColor.withAlphaComponent(0.3).cgColor
    }
    
    private let infoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 6
        $0.alignment = .center
    }
    
    private let titleLabel = UILabel().then {
        $0.font = AppFont.boldLargeTitle
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.textColor = AppColor.appPrimaryColor
    }
    
    private let semiInfoLabel = UILabel().then {
        $0.font = AppFont.subTitle
        $0.textColor = AppColor.appSecondaryColor
        $0.textAlignment = .center
    }
    
    private let genreLabel = UILabel().then {
        $0.font = AppFont.subTitle
        $0.textColor = AppColor.appSecondaryColor
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    
    private let actionButtonStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 20
    }

    private let watchlistButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "plus.circle")
        config.title = "보고 싶어요"
        config.attributedTitle?.font = AppFont.semiboldCallout
        config.imagePlacement = .top
        config.imagePadding = 8
        
        $0.configuration = config
    }
    
    private let watchedButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "eye")
        config.title = "시청함"
        config.attributedTitle?.font = AppFont.semiboldCallout
        config.imagePlacement = .top
        config.imagePadding = 8
        
        $0.configuration = config
    }
    
    private let reviewButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        
        config.image = UIImage(systemName: "sunglasses")
        config.preferredSymbolConfigurationForImage = .init(pointSize: 20)
        
        config.title = "평론하기"
        config.attributedTitle?.font = AppFont.semiboldCallout
        config.imagePlacement = .top
        config.imagePadding = 8
        
        $0.configuration = config
    }
    
    private let overviewLabel = UILabel().then {
        $0.font = AppFont.subTitle
        $0.numberOfLines = 0
        $0.textColor = AppColor.appBodyTextColor
        $0.textAlignment = .center
    }
    
    private lazy var creditsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .creditsCollectionViewLayout).then {
        $0.showsHorizontalScrollIndicator = false
        $0.register(CreditsCollectionViewCell.self, forCellWithReuseIdentifier: CreditsCollectionViewCell.cellID)
        $0.register(CreditsSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CreditsSectionHeader.reusableID)
        $0.showsVerticalScrollIndicator = false
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 12
        $0.backgroundColor = .clear
        $0.isScrollEnabled = false
    }
    
    private let imageProvider: ImageProviding
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    var disposeBag = DisposeBag()
    
    init(imageProvider: ImageProviding, mediaDBManager: MediaDBManager, reviewDBManager: ReviewDBManager) {
        self.imageProvider = imageProvider
        self.mediaDBManager = mediaDBManager
        self.reviewDBManager = reviewDBManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColor.appBackgroundColor
        configureHierarchy()
        configureLayout()
        configureNavigationBar()
        setupPlaceholderState()
        
        reactor?.action.onNext(.viewDidLoad)
    }
    
    private func configureNavigationBar() {
        navigationItem.title = "상세 정보"
    }
    
    func bind(reactor: MediaDetailReactor) {
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
                    if image == AppImage.emptyPosterImage {
                        owner.backDropImageView.contentMode = .scaleAspectFit
                        owner.backDropImageView.backgroundColor = .appSecondary
                        owner.backDropImageView.tintColor = .appPrimary
                    }
                    owner.backDropImageView.image = image
                } else {
                    owner.backDropImageView.backgroundColor = AppColor.secondaryBackgroundColor
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.posterImageData }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, image in
                if let image = image {
                    if image == AppImage.emptyPosterImage {
                        owner.posterImageView.contentMode = .scaleAspectFit
                        owner.posterImageView.backgroundColor = .appSecondary
                        owner.posterImageView.tintColor = .appPrimary
                    }
                    owner.posterImageView.image = image
                } else {
                    owner.posterImageView.backgroundColor = AppColor.secondaryBackgroundColor
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
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { ($0.isWatchlisted, $0.watchedDate, $0.isReviewed) }
            .compactMap { watchlisted, watchedDate, reviewed -> (Bool, Date?, Bool)? in
                return (watchlisted, watchedDate, reviewed)
            }
            .asDriver(onErrorJustReturn: (false, nil, false))
            .drive(with: self) { owner, statuses in
                let (isWatchlisted, watchedDate, isReviewed) = statuses
                
                owner.updateWatchlistButton(isWatchlisted: isWatchlisted)
                owner.updateWatchedButton(isWatchlisted: isWatchlisted, watchedDate: watchedDate)
                owner.updateReviewButton(watchedDate: watchedDate, isReviewed: isReviewed)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$pushWriteReviewView)
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, mediaInfo in
                guard let (media, id) = mediaInfo, let validObjectID = id else {
                    print("Media ObjectID 없음")
                    return
                }
                
                let reactor = WriteReviewReactor(mediaObjectID: validObjectID, title: media.title, posterPath: media.posterPath, imageProvider: owner.imageProvider, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager)
                let vc = WriteReviewViewController()
                vc.reactor = reactor
                owner.navigationController?.pushViewController(vc, animated: true)
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

        let dataSource = RxCollectionViewSectionedReloadDataSource<CreditsSectionModel>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item in
                guard let self = self, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreditsCollectionViewCell.cellID, for: indexPath) as? CreditsCollectionViewCell else { return UICollectionViewCell() }
                
                switch dataSource[indexPath] {
                case .casts(item: let cast):
                    let reactor = CreditsCollectionViewCellReactor(name: cast.name, role: cast.character, profilePath: cast.profilePath, imageLoader: self.imageProvider)
                    
                    cell.reactor = reactor
                    
                case .creators(item: let creator):
                    let reactor = CreditsCollectionViewCellReactor(name: creator.name, role: creator.department, profilePath: creator.profilePath, imageLoader: self.imageProvider)
                    
                    cell.reactor = reactor
                }
                
                return cell
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                guard kind == UICollectionView.elementKindSectionHeader else {
                    return UICollectionReusableView()
                }
                
                guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CreditsSectionHeader.reusableID, for: indexPath) as? CreditsSectionHeader else { return UICollectionReusableView() }
                
                let section = dataSource.sectionModels[indexPath.section]
                headerView.configureUI(header: section.header)
                
                return headerView
            }
        )
        
        let creditsStream = reactor.state.map { $0.credits }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .share()
        
        
        creditsStream
            .bind(to: creditsCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        creditsStream
            .bind(with: self) { owner, sectionModels in
                if sectionModels.count == 1 {
                    owner.creditsCollectionView.snp.remakeConstraints {
                        $0.top.equalTo(owner.overviewLabel.snp.bottom).offset(10)
                        $0.horizontalEdges.equalTo(owner.contentView).inset(20)
                        $0.height.equalTo(200)
                        $0.bottom.equalToSuperview().inset(10)
                    }
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func bindAction(reactor: MediaDetailReactor) {
        watchlistButton.rx.tap
            .map { MediaDetailReactor.Action.watchlistButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        watchedButton.rx.tap
            .map { MediaDetailReactor.Action.watchedButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reviewButton.rx.tap
            .map { MediaDetailReactor.Action.writeReviewButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func updateWatchlistButton(isWatchlisted: Bool) {
        var config = watchlistButton.configuration ?? UIButton.Configuration.plain()
        
        config.imagePlacement = .top
        config.imagePadding = 8
        config.preferredSymbolConfigurationForImage = .init(pointSize: 20)
        
        if isWatchlisted {
            config.title = "저장됨"
            config.image = UIImage(systemName: "bookmark.fill")
            config.baseForegroundColor = .systemYellow
        } else {
            config.title = "보고 싶어요"
            config.image = UIImage(systemName: "plus.circle")
            config.baseForegroundColor = AppColor.appPrimaryColor
        }
        
        let attr = attributedTitle(with: config.title ?? "")
        if let attr = try? AttributedString(attr, including: \.uiKit) {
            config.attributedTitle = attr
        }
        
        watchlistButton.configuration = config
    }
    
    private func updateWatchedButton(isWatchlisted: Bool, watchedDate: Date?) {
        watchedButton.isEnabled = isWatchlisted
        
        var config = watchedButton.configuration ?? UIButton.Configuration.plain()
        config.imagePlacement = .top
        config.imagePadding = 8
        config.preferredSymbolConfigurationForImage = .init(pointSize: 20)
        
        if let _ = watchedDate {
            config.title = "시청 완료"
            config.image = UIImage(systemName: "eye.fill")
            config.baseForegroundColor = AppColor.appPrimaryColor
        } else {
            config.title = "시청함"
            config.image = UIImage(systemName: "eye")
            config.baseForegroundColor = AppColor.appInactiveColor
        }
        
        let attr = attributedTitle(with: config.title ?? "")
        if let attr = try? AttributedString(attr, including: \.uiKit) {
            config.attributedTitle = attr
        }
        
        watchedButton.configuration = config
    }
    
    private func updateReviewButton(watchedDate: Date?, isReviewed: Bool) {
        let isEnabled = (watchedDate != nil)
        reviewButton.isEnabled = isEnabled
        
        var config = reviewButton.configuration ?? UIButton.Configuration.plain()
        config.imagePlacement = .top
        config.imagePadding = 8
        config.preferredSymbolConfigurationForImage = .init(pointSize: 20)
        
        if isReviewed {
            config.title = "평론 보기"
            config.image = UIImage(systemName: "doc.text.fill")
            config.baseForegroundColor = .systemGreen
        } else {
            config.title = "평론하기"
            config.image = UIImage(systemName: "sunglasses")
            config.baseForegroundColor = isEnabled ? AppColor.appPrimaryColor : AppColor.appInactiveColor
        }
        
        let attr = attributedTitle(with: config.title ?? "")
        if let attr = try? AttributedString(attr, including: \.uiKit) {
            config.attributedTitle = attr
        }
        
        reviewButton.configuration = config
    }
    
    private func attributedTitle(with text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        return NSAttributedString(
            string: text,
            attributes: [
                .font: AppFont.semiboldCallout,
                .paragraphStyle: paragraphStyle
            ]
        )
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
        [watchlistButton, watchedButton, reviewButton].forEach {
            actionButtonStackView.addArrangedSubview($0)
        }
        
        contentView.addSubview(overviewLabel)
        contentView.addSubview(creditsCollectionView)
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
            $0.height.equalTo(250)
            $0.centerX.equalTo(contentView)
        }
        
        shadowView.snp.makeConstraints {
            $0.centerY.equalTo(backDropImageView.snp.bottom).inset(20)
            $0.centerX.equalTo(contentView)
            $0.width.equalTo(view.bounds.width/3)
            $0.height.equalTo(shadowView.snp.width).multipliedBy(1.5)
        }
        
        posterImageView.snp.makeConstraints {
            $0.edges.equalTo(shadowView)
        }
        
        infoStackView.snp.makeConstraints {
            $0.top.equalTo(shadowView.snp.bottom).offset(10)
            $0.horizontalEdges.equalTo(contentView).inset(20)
        }
        
        actionButtonStackView.snp.makeConstraints {
            $0.top.equalTo(infoStackView.snp.bottom).offset(10)
            $0.centerX.equalTo(contentView)
        }
        
        [watchlistButton, watchedButton, reviewButton].forEach {
            $0.snp.makeConstraints { make in
                make.width.equalTo(90)
            }
        }
        
        overviewLabel.snp.makeConstraints {
            $0.top.equalTo(actionButtonStackView.snp.bottom).offset(10)
            $0.horizontalEdges.equalTo(contentView).inset(20)
        }
        
        creditsCollectionView.snp.makeConstraints {
            $0.top.equalTo(overviewLabel.snp.bottom).offset(10)
            $0.horizontalEdges.equalTo(contentView).inset(20)
            $0.height.equalTo(400)
            $0.bottom.equalToSuperview().inset(10)
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
            guard let self = self else { return }
            let selectedDate = datePicker.date
            self.reactor?.action.onNext(.updateWatchedDate(selectedDate))
        }
        
        present(alert, animated: true)
    }
    
    private func setupPlaceholderState() {
        backDropImageView.backgroundColor = AppColor.secondaryBackgroundColor
        posterImageView.backgroundColor = AppColor.secondaryBackgroundColor
        
        let placeholderColor = AppColor.placeholderTextColor
        
        [genreLabel, semiInfoLabel].forEach {
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
    }
    
    private func removePlaceholderState() {
        let placeholderLabels = [genreLabel, semiInfoLabel, overviewLabel]
        
        placeholderLabels.forEach {
            $0.backgroundColor = .clear
        }
        
        genreLabel.textColor = AppColor.appSecondaryColor
        semiInfoLabel.textColor = AppColor.appSecondaryColor
        overviewLabel.textColor = AppColor.appBodyTextColor
    }
}
