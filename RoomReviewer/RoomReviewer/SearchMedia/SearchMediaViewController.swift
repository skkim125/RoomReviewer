//
//  WriteReviewViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/1/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then

final class SearchMediaViewController: UIViewController {
    private let searchMediaCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .threeColumnCollectionViewLayout()).then {
        $0.register(SearchMediaCollectionViewCell.self, forCellWithReuseIdentifier: SearchMediaCollectionViewCell.cellID)
        $0.backgroundColor = .systemBackground
        $0.showsVerticalScrollIndicator = false
    }
    private let searchTextField = UITextField().then {
        $0.borderStyle = .roundedRect
        $0.font = .systemFont(ofSize: 14)
        $0.returnKeyType = .search
        $0.placeholder = "검색어를 입력하세요"
    }
    
    private let searchMediaReactor: SearchMediaReactor
    private let imageProvider: ImageProviding
    private let dbManager: DBManager
    private var disposeBag = DisposeBag()
    
    init(searchMediaReactor: SearchMediaReactor, imageProvider: ImageProviding, dbManager: DBManager) {
        self.searchMediaReactor = searchMediaReactor
        self.imageProvider = imageProvider
        self.dbManager = dbManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        configureHierarchy()
        configureLayout()
        configureNavigationBar()
        bind()
    }
    
    private func bind() {
        bindAction(reactor: searchMediaReactor)
        bindState(reactor: searchMediaReactor)
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
        
        self.navigationItem.leftBarButtonItem?.rx.tap
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
            .bind(to: searchMediaCollectionView.rx.items(cellIdentifier: SearchMediaCollectionViewCell.cellID, cellType: SearchMediaCollectionViewCell.self)) { [weak self] index, item, cell in
                guard let self = self else { return }
                let reactor = SearchMediaCollectionViewCellReactor(media: item, imageLoader: self.imageProvider)
                cell.configureCell(reactor: reactor, imageProvider: self.imageProvider)
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
                owner.navigationController?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$selectedMedia)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, media in
                let vc = MediaDetailViewController(reactor: MediaDetailReactor(media: media, networkService: NetworkManager(), imageProvider: owner.imageProvider, dbManager: owner.dbManager), imageProvider: owner.imageProvider)
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
            $0.bottom.equalToSuperview()
        }
    }
    
    private func configureNavigationBar() {
        navigationItem.title = "미디어 검색"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: nil, action: nil)
    }
}

extension UICollectionViewLayout {
    static func threeColumnCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0/3),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(180))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(10)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
