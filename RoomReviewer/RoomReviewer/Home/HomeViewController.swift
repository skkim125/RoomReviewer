//
//  HomeViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/13/25.
//

import UIKit
import ReactorKit
import RxDataSources
import SnapKit
import Then

final class HomeViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    private let imageProvider: ImageProviding
    private let imageFileManager: ImageFileManaging
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    private let networkManager: NetworkService
    private let networkMonitor: NetworkMonitoring
    
    private let homeCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .homeCollectionViewLayout).then {
        $0.register(TrendMediaCollectionViewCell.self, forCellWithReuseIdentifier: TrendMediaCollectionViewCell.cellID)
        $0.register(HotMediaCollectionViewCell.self, forCellWithReuseIdentifier: HotMediaCollectionViewCell.cellID)
        $0.register(HomeSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HomeSectionHeaderView.reusableID)
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .clear
    }
    
    private let writeReviewButton = UIBarButtonItem().then {
        let config = UIImage.SymbolConfiguration(weight: .heavy)
        let image = UIImage(systemName: "plus", withConfiguration: config)
        $0.image = image
        $0.tintColor = AppColor.appWhite
        $0.style = .done
        $0.target = nil
        $0.action = nil
    }
    
    init(imageProvider: ImageProviding, imageFileManager: ImageFileManaging, mediaDBManager: MediaDBManager, reviewDBManager: ReviewDBManager, networkManager: NetworkService, networkMonitor: NetworkMonitoring) {
        self.imageProvider = imageProvider
        self.imageFileManager = imageFileManager
        self.mediaDBManager = mediaDBManager
        self.reviewDBManager = reviewDBManager
        self.networkManager = networkManager
        self.networkMonitor = networkMonitor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.appBackgroundColor
        configureView()
        
        reactor?.action.onNext(.fetchData)
    }
    
    private func configureView() {
        configureHierarchy()
        configureLayout()
        configureNavigationBar()
    }
    
    func bind(reactor: HomeReactor) {
        writeReviewButton.rx.tap
            .map { HomeReactor.Action.writeButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        homeCollectionView.rx.modelSelected(HomeSectionModel.Item.self)
            .compactMap { item -> Media? in
                switch item {
                case .trend(let trend):
                    return trend
                case .watchlist(item: let watchlist):
                    return watchlist
                case .movie(let movie):
                    return movie
                case .tv(let tv):
                    return tv
                }
            }
            .map { HomeReactor.Action.mediaSelected($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<HomeSectionModel>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item in
                guard let self = self else { return UICollectionViewCell() }
                switch dataSource[indexPath] {
                case .trend(let trend):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrendMediaCollectionViewCell.cellID, for: indexPath) as? TrendMediaCollectionViewCell else { return UICollectionViewCell() }
                    
                    let reactor = TrendMediaCollectionViewCellReactor(media: trend, imageProvider: self.imageProvider)
                    cell.reactor = reactor
                    
                    return cell
                    
                case .watchlist(item: let watchList):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HotMediaCollectionViewCell.cellID, for: indexPath) as? HotMediaCollectionViewCell else { return UICollectionViewCell() }
                    let reactor = HotMediaCollectionViewCellReactor(media: watchList, imageProvider: self.imageProvider, imageFileManager: self.imageFileManager)
                    cell.reactor = reactor
                    
                    return cell
                    
                case .movie(let movie):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HotMediaCollectionViewCell.cellID, for: indexPath) as? HotMediaCollectionViewCell else { return UICollectionViewCell() }
                    let reactor = HotMediaCollectionViewCellReactor(media: movie, imageProvider: self.imageProvider, imageFileManager: self.imageFileManager)
                    cell.reactor = reactor
                    return cell
                    
                case .tv(let tv):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HotMediaCollectionViewCell.cellID, for: indexPath) as? HotMediaCollectionViewCell else { return UICollectionViewCell() }
                    let reactor = HotMediaCollectionViewCellReactor(media: tv, imageProvider: self.imageProvider, imageFileManager: imageFileManager)
                    cell.reactor = reactor
                    return cell
                }
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                guard kind == UICollectionView.elementKindSectionHeader else {
                    return UICollectionReusableView()
                }
                
                guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeSectionHeaderView.reusableID, for: indexPath) as? HomeSectionHeaderView else { return UICollectionReusableView() }
                
                let section = dataSource.sectionModels[indexPath.section]
                headerView.configureUI(header: section.header)
                
                return headerView
            }
        )
        
        reactor.state.map { $0.viewState }
            .compactMap { state -> [HomeSectionModel]? in
                guard case .loaded(let sections) = state else { return nil }
                return sections
            }
            .bind(to: homeCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.viewState }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, state in
                owner.updateUI(for: state)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$selectedMedia)
            .compactMap { $0 }
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, media in
                let detailReactor = MediaDetailReactor(media: media, networkService: owner.networkManager, imageProvider: owner.imageProvider, imageFileManager: owner.imageFileManager, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager, networkMonitor: owner.networkMonitor)
                let vc = MediaDetailViewController(imageProvider: owner.imageProvider, imageFileManager: owner.imageFileManager, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager)
                vc.reactor = detailReactor
                
                vc.updateAction = { [weak self] in
                    guard let self = self else { return }
                    self.reactor?.action.onNext(.updateWatchlist)
                }
                
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$presentWriteReviewView)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                let vc = SearchMediaViewController(networkMonitor: owner.networkMonitor, imageProvider: owner.imageProvider, imageFileManager: owner.imageFileManager, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager, isSheetView: true)
                let networkManager = NetworkManager(dataFetcher: URLSessionDataFetcher(networkMonitor: NetworkMonitor()))
                vc.reactor = SearchMediaReactor(networkService: networkManager)
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private var offlineVC: OfflineViewController?
    
    private func updateUI(for state: HomeReactor.State.ViewState) {
        switch state {
        case .loading:
            homeCollectionView.isHidden = true
            dismissOfflineVC()
        case .loaded:
            homeCollectionView.isHidden = false
            dismissOfflineVC()
        case .offline:
            homeCollectionView.isHidden = true
            presentOfflineVC()
        }
    }
    
    private func presentOfflineVC() {
        if self.offlineVC == nil {
            let vc = OfflineViewController()
            vc.retryAction = { [weak self] in
                self?.reactor?.action.onNext(.fetchData)
            }
            self.offlineVC = vc
            self.add(vc)
        }
    }
    
    private func dismissOfflineVC() {
        self.offlineVC?.remove()
        self.offlineVC = nil
    }
}

fileprivate extension UIViewController {
    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.view.frame = view.bounds
        child.didMove(toParent: self)
    }
    
    func remove() {
        guard parent != nil else { return }
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

extension HomeViewController {
    private func configureHierarchy() {
        view.addSubview(homeCollectionView)
    }
    
    private func configureLayout() {
        homeCollectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func configureNavigationBar() {
        let appIconView = UIView()
        let label = UILabel()
        label.font = AppFont.boldLargeTitle
        label.text = "방구석 평론가"
        label.textColor = AppColor.appWhite
        
        let image = UIImage(systemName: "sunglasses")
        let imageView = UIImageView(image: image)
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFill
        
        appIconView.addSubview(label)
        appIconView.addSubview(imageView)
        
        imageView.snp.makeConstraints {
            $0.leading.equalTo(appIconView).offset(2)
            $0.width.equalTo(50)
            $0.height.equalTo(20)
            $0.centerY.equalTo(appIconView)
        }
        
        label.snp.makeConstraints {
            $0.leading.equalTo(imageView.snp.trailing).offset(5)
            $0.centerY.equalTo(appIconView)
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: appIconView)
        navigationItem.rightBarButtonItem = writeReviewButton
    }
}
