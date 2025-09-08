//
//  SavedMediaViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/5/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import ReactorKit
import SnapKit
import Then

final class SavedMediaViewController: UIViewController, View {
    private var savedMediaCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .threeColumnPosterCollectionViewLayout).then {
        $0.register(ThreeColumnPosterCollectionViewCell.self, forCellWithReuseIdentifier: ThreeColumnPosterCollectionViewCell.cellID)
        $0.backgroundColor = .clear
    }
    
    private let dismissButton = UIBarButtonItem().then {
        $0.image = UIImage(systemName: "chevron.left")
        $0.tintColor = AppColor.appWhite
        $0.style = .done
        $0.target = nil
        $0.action = nil
    }
    
    private let networkService: NetworkService
    private let imageProvider: ImageProviding
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    
    var updateSections: (() -> Void)?
    var disposeBag = DisposeBag()
    
    init(networkService: NetworkService, imageProvider: ImageProviding, mediaDBManager: MediaDBManager, reviewDBManager: ReviewDBManager) {
        self.networkService = networkService
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
        configureHierarchy()
        configureLayout()
        configureNavigationBar()
        
        view.backgroundColor = AppColor.appBackgroundColor
    }
    
    private func configureHierarchy() {
        view.addSubview(savedMediaCollectionView)
    }
    
    private func configureLayout() {
        savedMediaCollectionView.snp.makeConstraints {
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(10)
            $0.verticalEdges.equalToSuperview()
        }
    }
    
    private func configureNavigationBar() {
        navigationItem.leftBarButtonItem = dismissButton
    }
    
    func bind(reactor: SavedMediaReactor) {
        bindState(reactor)
        bindAction(reactor)
    }
    
    private func bindState(_ reactor: SavedMediaReactor) {
        reactor.state.map { $0.savedMedia }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: savedMediaCollectionView.rx.items(cellIdentifier: ThreeColumnPosterCollectionViewCell.cellID, cellType: ThreeColumnPosterCollectionViewCell.self)) { [weak self] index, item, cell in
                guard let self = self else { return }
                let reactor = ThreeColumnPosterCollectionViewCellReactor(media: item, imageLoader: self.imageProvider)
                cell.reactor = reactor
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$selectedMedia)
            .compactMap { $0 }
            .bind(with: self) { owner, media in
                let detailReactor = MediaDetailReactor(media: media, networkService: owner.networkService, imageProvider: owner.imageProvider, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager)
                let vc = MediaDetailViewController(imageProvider: owner.imageProvider, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager)
                vc.reactor = detailReactor
                
                vc.updateAction = { [weak self]  in
                    guard let self = self else { return }
                    self.reactor?.action.onNext(.updateSavedMedias)
                }
                
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.navigationbarTitle }
            .asDriver(onErrorJustReturn: "")
            .drive(self.navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$dismissAction)
            .compactMap { $0 }
            .bind(with: self) { owner, _ in
                owner.updateSections?()
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$updateSavedMedias)
            .compactMap { $0 }
            .bind(with: self) { owner, _ in
                owner.savedMediaCollectionView.reloadData()
            }
            .disposed(by: disposeBag)
    }
    
    private func bindAction(_ reactor: SavedMediaReactor) {
        self.rx.methodInvoked(#selector(viewDidLoad))
            .map { _ in Reactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.rx.methodInvoked(#selector(viewWillAppear))
            .map { _ in Reactor.Action.updateSavedMedias }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        dismissButton.rx.tap
            .map { Reactor.Action.dismissSavedMediaView }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        savedMediaCollectionView.rx.modelSelected(Media.self)
            .map { Reactor.Action.selectedMedia($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
}
