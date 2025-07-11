//
//  HomeViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/13/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit
import Then

final class HomeViewController: UIViewController {
    private var disposeBag = DisposeBag()
    private let homeReactor: HomeReactor
    
    private let hotMediaCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .collectionViewLayout1).then {
        $0.register(HomeMediaCollectionViewCell.self, forCellWithReuseIdentifier: HomeMediaCollectionViewCell.cellID)
        $0.register(HomeSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HomeSectionHeaderView.reusableID)
        $0.backgroundColor = .white
        $0.showsHorizontalScrollIndicator = false
    }
    
    init(reactor: HomeReactor) {
        self.homeReactor = reactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        bind()
        
        homeReactor.action.onNext(.fetchData)
        
        view.backgroundColor = .white
    }
    
    private func configureView() {
        configureHierarchy()
        configureLayout()
        configureNavigationBar()
    }
    
    private func bind() {
        bindAction(reactor: homeReactor)
        bindState(reactor: homeReactor)
    }
    
    private func bindAction(reactor: HomeReactor) {
        self.navigationItem.rightBarButtonItem?.rx.tap
            .compactMap { HomeReactor.Action.writeButtonTapped }
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
            configureCell: { _, collectionView, indexPath, item in
                
                switch item {
                case .movie(item: let movie):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeMediaCollectionViewCell.cellID, for: indexPath) as? HomeMediaCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    let reactor = HomeMediaCollectionViewCellReactor(movie: movie)
                    cell.reactor = reactor
                    cell.bind(reactor: reactor)
                    
                    return cell
                    
                case .tv(item: let tv):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeMediaCollectionViewCell.cellID, for: indexPath) as? HomeMediaCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    let reactor = HomeMediaCollectionViewCellReactor(tv: tv)
                    cell.reactor = reactor
                    cell.bind(reactor: reactor)
                    
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
            .bind(to: hotMediaCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$presentWriteReviewView)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                let vc = WriteReviewViewController(writeReviewReactor: WriteReviewReactor(networkService: NetworkManager()))
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                owner.navigationController?.present(nav, animated: true)
            }
            .disposed(by: disposeBag)
    }
}

extension HomeViewController {
    private func configureHierarchy() {
        view.addSubview(hotMediaCollectionView)
    }
    
    private func configureLayout() {
        hotMediaCollectionView.snp.makeConstraints {
            $0.top.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func configureNavigationBar() {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.text = "방구석 평론가"
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: label)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "pencil"), style: .done, target: nil, action: nil)
    }
}

extension UICollectionViewLayout {
    static var collectionViewLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .init(top: 20, left: 20, bottom: 20, right: 20)
        layout.itemSize = CGSize(width: 170, height: 250)
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        layout.scrollDirection = .horizontal
        
        layout.headerReferenceSize = CGSize(width: 0, height: 50)
        
        return layout
    }
    
    static var collectionViewLayout1: UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
                
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.3),
                    heightDimension: .fractionalHeight(0.25)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 15
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 20, trailing: 15)
                
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [header]
                
                return section
            }
            
            return layout
    }
}
