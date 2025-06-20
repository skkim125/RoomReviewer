//
//  HomeViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/13/25.
//

import UIKit
import RxSwift
import RxCocoa
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
        
        view.backgroundColor = .white
    }
    
    private func configureView() {
        configureHierarchy()
        configureLayout()
    }
    
    private func bind() {
        bindAction(reactor: homeReactor)
        bindState(reactor: homeReactor)
    }
    
    private func bindAction(reactor: HomeReactor) {
        rx.methodInvoked(#selector(viewWillAppear)).map { _ in }
            .map { HomeReactor.Action.fetchData }
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
            
        reactor.state.map { $0.tvs }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: homeTVCollectionView.rx.items(cellIdentifier: HomeTVCollectionViewCell.cellID, cellType: HomeTVCollectionViewCell.self)) { row, tv, cell in
                let reactor = HomeTVCollectionViewCellReactor(tv: tv)
                cell.reactor = reactor
                cell.bind(reactor: reactor)
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
