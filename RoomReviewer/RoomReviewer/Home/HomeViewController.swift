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
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    
    private let homeCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .homeCollectionViewLayout).then {
        $0.register(TrendMediaCollectionViewCell.self, forCellWithReuseIdentifier: TrendMediaCollectionViewCell.cellID)
        $0.register(HotMediaCollectionViewCell.self, forCellWithReuseIdentifier: HotMediaCollectionViewCell.cellID)
        $0.register(HomeSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HomeSectionHeaderView.reusableID)
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .clear
    }
    
    private let writeReviewButton = UIBarButtonItem().then {
        $0.image = UIImage(systemName: "pencil")
        $0.style = .done
        $0.target = nil
        $0.action = nil
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
        configureView()
        
        reactor?.action.onNext(.fetchData)
    }
    
    private func configureView() {
        configureHierarchy()
        configureLayout()
        configureNavigationBar()
    }
    
    func bind(reactor: HomeReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: HomeReactor) {
        writeReviewButton.rx.tap
            .compactMap { HomeReactor.Action.writeButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.homeCollectionView.rx.modelSelected(HomeSectionModel.Item.self)
            .compactMap { item -> Media? in
                switch item {
                case .trend(let trend):
                    return trend
                case .movie(let movie):
                    return movie
                case .tv(let tv):
                    return tv
                }
            }
            .map { HomeReactor.Action.mediaSelected($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: HomeReactor) {
        reactor.state.map({ $0.isLoading })
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, value in
                
            }
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
                    
                case .movie(let movie):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HotMediaCollectionViewCell.cellID, for: indexPath) as? HotMediaCollectionViewCell else { return UICollectionViewCell() }
                    let cellReactor = HotMediaCollectionViewCellReactor(media: movie, imageProvider: self.imageProvider)
                    cell.configureCell(reactor: cellReactor, imageProvider: self.imageProvider)
                    return cell
                    
                case .tv(let tv):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HotMediaCollectionViewCell.cellID, for: indexPath) as? HotMediaCollectionViewCell else { return UICollectionViewCell() }
                    let cellReactor = HotMediaCollectionViewCellReactor(media: tv, imageProvider: self.imageProvider)
                    cell.configureCell(reactor: cellReactor, imageProvider: self.imageProvider)
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
        
        reactor.state.map { $0.medias }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: homeCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$selectedMedia)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, media in
                let detailReactor = MediaDetailReactor(media: media, networkService: NetworkManager(), imageProvider: owner.imageProvider, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager)
                let vc = MediaDetailViewController(imageProvider: owner.imageProvider, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager)
                vc.reactor = detailReactor
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$presentWriteReviewView)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                let vc = SearchMediaViewController(imageProvider: owner.imageProvider, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager)
                vc.reactor = SearchMediaReactor(networkService: NetworkManager())
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                owner.navigationController?.present(nav, animated: true)
            }
            .disposed(by: disposeBag)
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
        let label = UILabel()
        label.font = AppFont.appIconTitle
        label.text = "방구석 평론가"
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: label)
        navigationItem.rightBarButtonItem = writeReviewButton
    }
}
