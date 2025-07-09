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
    
    private let homeTVCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .collectionViewLayout).then {
        $0.register(HomeTVCollectionViewCell.self, forCellWithReuseIdentifier: HomeTVCollectionViewCell.cellID)
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
            
        let dataSource = RxCollectionViewSectionedReloadDataSource<HomeSectionModel> (configureCell: { _, collectionView, indexPath, item in
            
            switch item {
            case .movie(item: let tv):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTVCollectionViewCell.cellID, for: indexPath) as? HomeTVCollectionViewCell else {
                    return UICollectionViewCell()
                }
                let reactor = HomeTVCollectionViewCellReactor(media: tv)
                cell.reactor = reactor
                cell.bind(reactor: reactor)
                
                return cell
                
            case .tv(item: let tv):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTVCollectionViewCell.cellID, for: indexPath) as? HomeTVCollectionViewCell else {
                    return UICollectionViewCell()
                }
                let reactor = HomeTVCollectionViewCellReactor(media: tv)
                cell.reactor = reactor
                cell.bind(reactor: reactor)
                
                return cell
            }
        })
        
        reactor.state.map { $0.medias }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: homeTVCollectionView.rx.items(dataSource: dataSource))
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
        view.addSubview(homeTVCollectionView)
    }
    
    private func configureLayout() {
        homeTVCollectionView.snp.makeConstraints {
            $0.top.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(280)
        }
    }
    
    private func configureNavigationBar() {
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
        
        return layout
    }
}
