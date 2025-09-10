//
//  MediaTierListViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/10/25.
//

import UIKit
import ReactorKit
import RxDataSources
import SnapKit
import Then

final class MediaTierListViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: .mediaTierListLayout).then {
        $0.backgroundColor = .clear
        $0.register(PosterCollectionViewCell.self, forCellWithReuseIdentifier: PosterCollectionViewCell.cellID)
        $0.register(TierSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TierSectionHeaderView.reusableID)
    }
    private let imageProvider: ImageProviding
    
    init(imageProvider: ImageProviding) {
        self.imageProvider = imageProvider
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
    
    func configureHierarchy() {
        view.addSubview(collectionView)
    }
    
    private func configureLayout() {
        collectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func configureNavigationBar() {
        self.navigationItem.title = "미디어 티어리스트"
    }
    
    func bind(reactor: MediaTierListReactor) {
        self.rx.methodInvoked(#selector(viewDidLoad))
            .map { _ in Reactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
            
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<MediaTierListSectionModel>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item in
                guard let self = self else { return UICollectionViewCell() }
                
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PosterCollectionViewCell.cellID, for: indexPath) as? PosterCollectionViewCell else { return UICollectionViewCell() }
                
                let media: Media
                switch item {
                case .ranked(let rankedMedia):
                    media = rankedMedia
                case .unranked(let unrankedMedia):
                    media = unrankedMedia
                }
                
                cell.reactor = ThreeColumnPosterCollectionViewCellReactor(media: media, imageLoader: self.imageProvider)
                return cell
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TierSectionHeaderView.reusableID, for: indexPath) as? TierSectionHeaderView else { return UICollectionReusableView() }
                
                let section = dataSource[indexPath.section]
                
                switch section {
                case .tier(let tier, _):
                    header.configure(title: section.title, color: tier.color)
                case .unranked:
                    header.configure(title: section.title, color: .darkGray)
                }
                
                return header
            }
        )
        
        reactor.state
            .map { $0.sections }
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
}
