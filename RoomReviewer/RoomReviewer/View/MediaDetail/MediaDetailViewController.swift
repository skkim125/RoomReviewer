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
import FirebaseAnalytics

final class MediaDetailViewController: UIViewController, View {
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }
    
    private let activityIndicator = UIActivityIndicatorView(style: .large).then {
        $0.color = AppColor.appWhite
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
        $0.layer.borderColor = AppColor.appWhite.withAlphaComponent(0.3).cgColor
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
        $0.textColor = AppColor.appWhite
    }
    
    private let semiInfoLabel = UILabel().then {
        $0.font = AppFont.subTitle
        $0.textColor = AppColor.appLightGray
        $0.textAlignment = .center
    }
    
    private let genreLabel = UILabel().then {
        $0.font = AppFont.subTitle
        $0.textColor = AppColor.appLightGray
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
        $0.isEnabled = false
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
        $0.numberOfLines = 4
        $0.textColor = AppColor.appWhite
        $0.textAlignment = .left
    }
    
    private let moreOverviewButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        config.preferredSymbolConfigurationForImage = symbolConfig
        config.image = UIImage(systemName: "chevron.down")
        config.title = "더보기"
        config.imagePlacement = .trailing
        config.imagePadding = 2
        config.baseForegroundColor = AppColor.appLightGray
        if let attributed = try? AttributedString(NSAttributedString(string: "더보기", attributes: [.font: AppFont.semiboldCallout]), including: \.uiKit) {
            config.attributedTitle = attributed
        }
        $0.configuration = config
    }
    
    private let backButton = UIBarButtonItem().then {
        $0.image = UIImage(systemName: "chevron.left")
        $0.tintColor = AppColor.appWhite
        $0.style = .done
        $0.target = nil
        $0.action = nil
    }
    
    private let starToggleButton = UIBarButtonItem().then {
        $0.image = UIImage(systemName: "star")
        $0.tintColor = .appYellow
        $0.style = .done
        $0.target = nil
        $0.action = nil
    }
    
    private lazy var creditsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .mediaDetailCollectionViewLayout).then {
        $0.showsHorizontalScrollIndicator = false
        $0.register(CreditsCollectionViewCell.self, forCellWithReuseIdentifier: CreditsCollectionViewCell.cellID)
        $0.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: VideoCollectionViewCell.cellID)
        $0.register(SeeMoreCollectionViewCell.self, forCellWithReuseIdentifier: SeeMoreCollectionViewCell.cellID)
        $0.register(CreditsSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CreditsSectionHeader.reusableID)
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .clear
        $0.isScrollEnabled = false
    }
    
    private let imageProvider: ImageProviding
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    
    private let overviewStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 5
        $0.alignment = .fill
    }

    var updateAction: (() -> Void)?
    var disposeBag = DisposeBag()
    
    deinit {
        print("MediaDetailViewController deinit")
    }
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "MediaDetail",
            AnalyticsParameterScreenClass: "MediaDetailViewController"
        ])
        
        if let reactor = self.reactor {
            reactor.action.onNext(.viewWillAppear)
        }
    }
    
    private func configureNavigationBar() {
        navigationItem.title = "상세 정보"
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = backButton
        self.navigationItem.rightBarButtonItem = starToggleButton
    }
    
    func bind(reactor: MediaDetailReactor) {
        bindState(reactor: reactor)
        bindAction(reactor: reactor)
        
        reactor.action.onNext(.viewDidLoad)
    }
    
    private func bindState(reactor: MediaDetailReactor) {
        reactor.state.map { !$0.areImagesLoaded }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.isEssentialDataLoaded }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(with: self) { owner, isLoaded in
                if isLoaded {
                    owner.removePlaceholderState()
                } else {
                    owner.setupPlaceholderState()
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.areImagesLoaded }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(
                watchlistButton.rx.isEnabled,
                watchedButton.rx.isEnabled,
                reviewButton.rx.isEnabled,
                starToggleButton.rx.isEnabled
            )
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.genres }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(genreLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { !$0.isOverviewButtonVisible }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: true)
            .drive(moreOverviewButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.overview }
            .distinctUntilChanged()
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: "")
            .do { [weak self] overviewText in
                guard let self = self else { return }
                self.checkOverviewButtonVisible(text: overviewText)
            }
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
                        owner.backDropImageView.backgroundColor = AppColor.appLightGray
                        owner.backDropImageView.tintColor = AppColor.appWhite
                    } else {
                        owner.backDropImageView.contentMode = .scaleAspectFill
                    }
                    owner.backDropImageView.image = image
                } else {
                    owner.backDropImageView.backgroundColor = AppColor.appDarkGray
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
                        owner.posterImageView.backgroundColor = AppColor.appLightGray
                        owner.posterImageView.tintColor = AppColor.appWhite
                    } else {
                        owner.posterImageView.contentMode = .scaleAspectFill
                    }
                    owner.posterImageView.image = image
                } else {
                    owner.posterImageView.backgroundColor = AppColor.appDarkGray
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { ($0.isWatchlisted, $0.watchedDate, $0.isReviewed) }
            .asDriver(onErrorJustReturn: (false, nil, false))
            .drive(with: self) { owner, statuses in
                let (isWatchlisted, watchedDate, isReviewed) = statuses
                owner.updateWatchlistButton(isWatchlisted: isWatchlisted, isReviewed: isReviewed, watchedDate: watchedDate)
                owner.updateWatchedButton(isWatchlisted: isWatchlisted, watchedDate: watchedDate)
                owner.updateReviewButton(watchedDate: watchedDate, isReviewed: isReviewed)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$pushWriteReviewView)
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, mediaInfo in
                guard let (media, reviewEntity) = mediaInfo else { return }
                let reactor = WriteReviewReactor(media: media, review: reviewEntity, imageProvider: owner.imageProvider, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager)
                let vc = WriteReviewViewController(imageProvider: owner.imageProvider)
                vc.reactor = reactor
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$showSetWatchedDateAlert)
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, flag in
                if let _ = flag { owner.presentCalendarAlert() }
            }
            .disposed(by: disposeBag)

        let dataSource = RxCollectionViewSectionedReloadDataSource<MediaDetailSectionModel>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item in
                guard let self = self else { return UICollectionViewCell() }
                
                switch item {
                case .cast(let cast):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreditsCollectionViewCell.cellID, for: indexPath) as? CreditsCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    cell.reactor = CreditsCollectionViewCellReactor(name: cast.name, role: cast.character, profilePath: cast.profilePath, imageLoader: self.imageProvider)
                    return cell
                    
                case .creator(let creator):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreditsCollectionViewCell.cellID, for: indexPath) as? CreditsCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    cell.reactor = CreditsCollectionViewCellReactor(name: creator.name, role: creator.department, profilePath: creator.profilePath, imageLoader: self.imageProvider)
                    return cell
                    
                case .seeMore:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SeeMoreCollectionViewCell.cellID, for: indexPath) as? SeeMoreCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    return cell
                    
                case .video(let video):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionViewCell.cellID, for: indexPath) as? VideoCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    
                    cell.reactor = VideoCollectionViewCellReactor(videoName: video.name, videoKey: video.key, imageLoader: self.imageProvider)
                    return cell
                }
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CreditsSectionHeader.reusableID, for: indexPath) as? CreditsSectionHeader else { return UICollectionReusableView() }
                headerView.configureUI(header: dataSource[indexPath.section].header)
                return headerView
            }
        )
        
        let dataStream = reactor.state.map { $0.mediaDetailSectionModels }
            .distinctUntilChanged()
            .share()
        
        dataStream
            .bind(to: creditsCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        dataStream
            .asDriver(onErrorJustReturn: [])
            .drive(with: self) { owner, sections in
                
                var totalHeight: CGFloat = 0.0
                
                sections.forEach { section in
                    switch section {
                    case .creators(let items):
                        if !items.isEmpty { totalHeight += 160 }
                        
                    case .casts(let items):
                        if !items.isEmpty { totalHeight += 210 }
                        
                    case .seeMore(let items):
                        if !items.isEmpty { totalHeight += 40 }
                        
                    case .videos(let items):
                        if !items.isEmpty {
                            let width = UIScreen.main.bounds.width * 0.9
                            totalHeight += (width * 9 / 16) + 35 + AppFont.semiboldSubTitle.lineHeight
                        }
                    }
                }
                
                owner.creditsCollectionView.snp.updateConstraints {
                    $0.height.equalTo(totalHeight)
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.isOverviewExpanded }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(with: self) { owner, isExpanded in
                owner.expandOverview(isExpanded: isExpanded)
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.isStared }
            .asDriver(onErrorJustReturn: false)
            .drive(with: self) { owner, isStar in
                owner.starToggleButton.image = isStar ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
            }
            .disposed(by: disposeBag)
            
        reactor.pulse(\.$showNetworkErrorAndDismiss)
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: ())
            .drive(with: self) { owner, _ in
                owner.showNetworkErrorAlertAndDismiss()
            }
            .disposed(by: disposeBag)
            
        reactor.pulse(\.$error)
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: NetworkError.commonError)
            .drive(with: self) { owner, error in
                owner.showErrorAlert(error: error)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$showMoveYoutubeAlert)
            .map { $0 }
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, video in
                owner.showMoveYoutubeAlert(video)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$showUpdateCompleteAlert)
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: ())
            .drive(with: self) { owner, _ in
                owner.showUpdateCompleteAlert()
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$pushCreditsListView)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, credits in
                let vc = CreditListViewController(imageProvider: owner.imageProvider)
                vc.reactor = CreditListReactor(credits: credits)
                
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindAction(reactor: MediaDetailReactor) {
        watchlistButton.rx.tap
            .do(onNext: { [weak reactor] in
                guard let reactor = reactor else { return }
                let state = reactor.currentState
                Analytics.logEvent("detail_watchlist_tapped", parameters: ["media_id": state.media.id, "media_type": state.media.mediaType.rawValue, "media_title": state.media.title, "is_watchlisted_after_tap": !state.isWatchlisted])
            })
            .map { MediaDetailReactor.Action.watchlistButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        watchedButton.rx.tap
            .do(onNext: { [weak reactor] _ in
                guard let reactor = reactor else { return }
                let state = reactor.currentState
                Analytics.logEvent("detail_watched_tapped", parameters: ["media_id": state.media.id, "media_type": state.media.mediaType.rawValue, "media_title": state.media.title])
            })
            .map { MediaDetailReactor.Action.watchedButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reviewButton.rx.tap
            .do(onNext: { [weak reactor] _ in
                guard let reactor = reactor else { return }
                let state = reactor.currentState
                Analytics.logEvent("detail_review_tapped", parameters: ["media_id": state.media.id, "media_type": state.media.mediaType.rawValue, "media_title": state.media.title])
            })
            .map { MediaDetailReactor.Action.writeReviewButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        moreOverviewButton.rx.tap
            .map { MediaDetailReactor.Action.moreOverviewButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        backButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.updateAction?()
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        starToggleButton.rx.tap
            .do(onNext: { [weak reactor] in
                guard let reactor = reactor else { return }
                let state = reactor.currentState
                Analytics.logEvent("detail_star_tapped", parameters: ["media_id": state.media.id, "media_type": state.media.mediaType.rawValue, "media_title": state.media.title, "is_stared_after_tap": !state.isStared])
            })
            .map { MediaDetailReactor.Action.starButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        creditsCollectionView.rx.modelSelected(MediaDetailSectionModel.Item.self)
            .compactMap { item -> Reactor.Action? in
                switch item {
                case .cast, .creator:
                    return nil
                case .video(item: let video):
                    return Reactor.Action.videoSelected(video)
                case .seeMore:
                    return Reactor.Action.seeMoreCreditsButtonTapped
                }
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func updateWatchlistButton(isWatchlisted: Bool, isReviewed: Bool, watchedDate: Date?) {
        let areImagesLoaded = reactor?.currentState.areImagesLoaded ?? false
        let logicEnabled = (isReviewed == false && watchedDate == nil)
        watchlistButton.isEnabled = logicEnabled && areImagesLoaded
        
        var config = watchlistButton.configuration ?? UIButton.Configuration.plain()
        
        config.imagePlacement = .top
        config.imagePadding = 8
        config.preferredSymbolConfigurationForImage = .init(pointSize: 20)
        
        if isWatchlisted {
            config.title = "저장됨"
            config.image = UIImage(systemName: "bookmark.fill")
            config.baseForegroundColor = .appYellow
        } else {
            config.title = "보고 싶어요"
            config.image = UIImage(systemName: "plus.circle")
            config.baseForegroundColor = AppColor.appWhite
        }
        
        let attr = attributedTitle(text: config.title ?? "", alignment: .center)
        if let attr = try? AttributedString(attr, including: \.uiKit) {
            config.attributedTitle = attr
        }
        
        watchlistButton.configuration = config
    }
    
    private func updateWatchedButton(isWatchlisted: Bool, watchedDate: Date?) {
        let areImagesLoaded = reactor?.currentState.areImagesLoaded ?? false
        let logicEnabled = isWatchlisted
        watchedButton.isEnabled = logicEnabled && areImagesLoaded
        
        var config = watchedButton.configuration ?? UIButton.Configuration.plain()
        config.imagePlacement = .top
        config.imagePadding = 8
        config.preferredSymbolConfigurationForImage = .init(pointSize: 20)
        
        if let _ = watchedDate {
            config.title = "시청 완료"
            config.image = UIImage(systemName: "eye.fill")
            config.baseForegroundColor = AppColor.appWhite
        } else {
            config.title = "시청함"
            config.image = UIImage(systemName: "eye")
            config.baseForegroundColor = AppColor.appGray
        }
        
        let attr = attributedTitle(text: config.title ?? "", alignment: .center)
        if let attr = try? AttributedString(attr, including: \.uiKit) {
            config.attributedTitle = attr
        }
        
        watchedButton.configuration = config
    }
    
    private func updateReviewButton(watchedDate: Date?, isReviewed: Bool) {
        let areImagesLoaded = reactor?.currentState.areImagesLoaded ?? false
        let logicEnabled = (watchedDate != nil)
        reviewButton.isEnabled = logicEnabled && areImagesLoaded
        
        var config = reviewButton.configuration ?? UIButton.Configuration.plain()
        config.imagePlacement = .top
        config.imagePadding = 8
        config.preferredSymbolConfigurationForImage = .init(pointSize: 20)
        
        if isReviewed {
            config.title = "평론 보기"
            config.image = UIImage(systemName: "sunglasses.fill")
            config.baseForegroundColor = .appButtonRed
        } else {
            config.title = "평론하기"
            config.image = UIImage(systemName: "sunglasses")
            config.baseForegroundColor = logicEnabled ? AppColor.appWhite : AppColor.appGray
        }
        
        let attr = attributedTitle(text: config.title ?? "", alignment: .center)
        if let attr = try? AttributedString(attr, including: \.uiKit) {
            config.attributedTitle = attr
        }
        
        reviewButton.configuration = config
    }
    
    private func attributedTitle(text: String, alignment: NSTextAlignment) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        return NSAttributedString(
            string: text,
            attributes: [
                .font: AppFont.semiboldCallout,
                .paragraphStyle: paragraphStyle
            ]
        )
    }
    
    private func expandOverview(isExpanded: Bool) {
        UIView.transition(with: moreOverviewButton, duration: 0.05, options: .transitionCrossDissolve, animations: {
            var config = self.moreOverviewButton.configuration ?? UIButton.Configuration.plain()
            let title = isExpanded ? "접기" : "더보기"
            let image = isExpanded ? UIImage(systemName: "chevron.up") : UIImage(systemName: "chevron.down")
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            
            config.image = image
            config.preferredSymbolConfigurationForImage = symbolConfig
            
            let attr = NSAttributedString(
                string: title,
                attributes: [.font: AppFont.subTitle]
            )
            if let attributed = try? AttributedString(attr, including: \.uiKit) {
                config.attributedTitle = attributed
            }
            
            self.moreOverviewButton.configuration = config
        })
        
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseInOut, animations: {
            self.overviewLabel.numberOfLines = isExpanded ? 0 : 4
        })
    }
    
    private func checkOverviewButtonVisible(text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let reactor = self.reactor else { return }
            
            let maxHeight = self.overviewLabel.font.lineHeight * 4.1
            
            let fullHeight = text.height(width: self.overviewLabel.bounds.width, font: self.overviewLabel.font)
            
            let isVisible = fullHeight > maxHeight
            
            reactor.action.onNext(.setOverviewButtonVisible(isVisible))
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
        [watchlistButton, watchedButton, reviewButton].forEach {
            actionButtonStackView.addArrangedSubview($0)
        }

        contentView.addSubview(overviewStackView)
        [overviewLabel, moreOverviewButton].forEach {
            overviewStackView.addArrangedSubview($0)
        }
        
        contentView.addSubview(creditsCollectionView)
        
        view.addSubview(activityIndicator)
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
            $0.height.equalTo(view.bounds.height/3)
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
        
        overviewStackView.snp.makeConstraints {
            $0.top.equalTo(actionButtonStackView.snp.bottom).offset(10)
            $0.horizontalEdges.equalTo(contentView).inset(20)
        }
        
        creditsCollectionView.snp.makeConstraints {
            $0.top.equalTo(overviewStackView.snp.bottom).offset(5)
            $0.horizontalEdges.equalTo(contentView).inset(5)
            $0.height.equalTo(0)
            $0.bottom.equalTo(contentView).inset(10)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}

extension MediaDetailViewController {
    private func presentCalendarAlert() {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.tintColor = .appRed
        datePicker.locale = Locale(identifier: "ko-KR")
        datePicker.maximumDate = Date()
        
        if let currentWatchedDate = reactor?.currentState.watchedDate {
            datePicker.date = currentWatchedDate
        }
        
        let alert = CustomAlertViewController(title: "시청한 날짜 선택", subtitle: "미디어를 시청한 날짜를 선택해주세요.", buttonType: .twoButton, contentView: datePicker) { [weak self] in
            guard let self = self else { return }
            let selectedDate = datePicker.date
            self.reactor?.action.onNext(.updateWatchedDate(selectedDate))
            guard let state = self.reactor?.currentState else { return }
            Analytics.logEvent("update_WatchedDate", parameters: [
                "WatchedDate_Date": selectedDate.formatted(date: .numeric, time: .standard),
                "WatchedDate_MediaTitle": state.media.title,
            ])
        }
        
        present(alert, animated: true)
    }
    
    private func setupPlaceholderState() {
        backDropImageView.backgroundColor = AppColor.appDarkGray
        posterImageView.backgroundColor = AppColor.appDarkGray
        
        let placeholderColor = AppColor.appPlaceholder
        
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
        
        genreLabel.textColor = AppColor.appLightGray
        semiInfoLabel.textColor = AppColor.appLightGray
        overviewLabel.textColor = AppColor.appWhite
    }
    
    private func showNetworkErrorAlertAndDismiss() {
        let alert = CustomAlertViewController(
            title: "네트워크 오류",
            subtitle: "네트워크 연결을 확인해주세요.",
            buttonType: .oneButton
        ) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        present(alert, animated: true)
    }
    
    private func showMoveYoutubeAlert(_ video: Video?) {
        guard let video = video else { return }
        
        let alert = CustomAlertViewController(
            title: "시청을 위해 Youtube로 이동하겠습니까?",
            subtitle: "Youtube로 이동합니다.",
            buttonType: .twoButton
        ) { [weak self] in
            self?.openYouTubeVideo(id: video.key)
        }
        
        present(alert, animated: true)
    }
    
    private func showErrorAlert(error: Error) {
        let alert = CustomAlertViewController(
            title: "오류 발생",
            subtitle: error.localizedDescription,
            buttonType: .oneButton
        )
        present(alert, animated: true)
    }
    
    private func showUpdateCompleteAlert() {
        let alert = CustomAlertViewController(
            title: "업데이트 완료",
            subtitle: "최신 정보로 업데이트되었습니다.",
            buttonType: .oneButton
        )
        present(alert, animated: true)
    }
    
    private func openYouTubeVideo(id: String) {
        let appURL = URL(string: "youtube://www.youtube.com/watch?v=\(id)")!
        let webURL = URL(string: "https://www.youtube.com/watch?v=\(id)")!
        let application = UIApplication.shared
        
        if application.canOpenURL(appURL) {
            application.open(appURL)
        } else {
            application.open(webURL)
        }
    }
}
