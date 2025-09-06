//
//  WriteReviewViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/1/25.
//

import UIKit
import ReactorKit
import RxCocoa
import SnapKit
import Then

final class SearchMediaViewController: UIViewController, View {
    private let searchMediaCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .threeColumnPosterCollectionViewLayout).then {
        $0.register(ThreeColumnPosterCollectionViewCell.self, forCellWithReuseIdentifier: ThreeColumnPosterCollectionViewCell.cellID)
        $0.backgroundColor = .clear
        $0.showsVerticalScrollIndicator = false
    }
    private let searchTextField = UITextField().then {
        $0.borderStyle = .roundedRect
        $0.font = AppFont.subTitle
        $0.returnKeyType = .search
        $0.placeholder = "검색어를 입력하세요"
    }
    
    private let dismissButton = UIBarButtonItem().then {
        $0.image = UIImage(systemName: "chevron.left")
        $0.tintColor = AppColor.appWhite
        $0.style = .done
        $0.target = nil
        $0.action = nil
    }
    
    private let isSheetView: Bool
    
    private let imageProvider: ImageProviding
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    var disposeBag = DisposeBag()
    
    init(imageProvider: ImageProviding, mediaDBManager: MediaDBManager, reviewDBManager: ReviewDBManager, isSheetView: Bool = false) {
        self.imageProvider = imageProvider
        self.mediaDBManager = mediaDBManager
        self.reviewDBManager = reviewDBManager
        self.isSheetView = isSheetView
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
    
    func bind(reactor: SearchMediaReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: SearchMediaReactor) {
        searchTextField.rx.text
            .distinctUntilChanged()
            .map { SearchMediaReactor.Action.updateQuery($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        searchTextField.rx.controlEvent(.editingDidEndOnExit)
            .map { SearchMediaReactor.Action.searchButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        dismissButton.rx.tap
            .map { SearchMediaReactor.Action.dismissWriteReview }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        searchMediaCollectionView.rx.modelSelected(Media.self)
            .map { SearchMediaReactor.Action.selectedMedia($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: SearchMediaReactor) {
        
        reactor.pulse(\.$searchResults)
            .compactMap { $0 }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: searchMediaCollectionView.rx.items(cellIdentifier: ThreeColumnPosterCollectionViewCell.cellID, cellType: ThreeColumnPosterCollectionViewCell.self)) { [weak self] index, item, cell in
                guard let self = self else { return }
                let reactor = ThreeColumnPosterCollectionViewCellReactor(media: item, imageLoader: self.imageProvider)
                cell.reactor = reactor
            }
            .disposed(by: disposeBag)
        

        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, value in
                owner.searchTextField.isEnabled = !value
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$errorType)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, value in
                print("검색 에러")
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$dismissAction)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$selectedMedia)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, media in
                let reactor = MediaDetailReactor(media: media, networkService: NetworkManager(), imageProvider: owner.imageProvider, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager)
                let vc = MediaDetailViewController(imageProvider: owner.imageProvider, mediaDBManager: owner.mediaDBManager, reviewDBManager: owner.reviewDBManager)
                vc.reactor = reactor
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)
    }
}

extension SearchMediaViewController {
    private func configureHierarchy() {
        view.addSubview(searchTextField)
        view.addSubview(searchMediaCollectionView)
    }
    
    private func configureLayout() {
        searchTextField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(40)
        }
        
        searchMediaCollectionView.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom).offset(10)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(10)
            if self.isSheetView {
                $0.bottom.equalToSuperview()
            } else {
                $0.bottom.equalTo(view.safeAreaLayoutGuide)
            }
        }
    }
    
    private func configureNavigationBar() {
        if isSheetView {
            navigationItem.leftBarButtonItem = dismissButton
            navigationItem.title = "컨텐츠 검색"
        } else {
            let appIconView = UIView()
            let label = UILabel()
            label.font = AppFont.boldLargeTitle
            label.text = "컨텐츠 검색"
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
        }
    }
}
