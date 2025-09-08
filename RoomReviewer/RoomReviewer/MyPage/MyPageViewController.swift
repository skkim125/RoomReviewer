//
//  MyPageViewController.swift
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

final class MyPageViewController: UIViewController, View {
    private var myPageCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .myPageCollectionViewLayout).then {
        $0.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "listCell")
        $0.register(MyPageHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MyPageHeaderView.reusableID)
        $0.backgroundColor = .clear
    }
    
    var disposeBag = DisposeBag()
    
    private let networkService: NetworkService
    private let imageProvider: ImageProviding
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    
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
    
    func configureHierarchy() {
        view.addSubview(myPageCollectionView)
    }
    
    private func configureLayout() {
        myPageCollectionView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
    
    private func configureNavigationBar() {
        let appIconView = UIView()
        let label = UILabel()
        label.font = AppFont.boldLargeTitle
        label.text = "더보기"
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
    
    func bind(reactor: MyPageReactor) {
        bindState(reactor)
        bindAction(reactor)
    }
    
    private func bindState(_ reactor: MyPageReactor) {
        let dataSource = RxCollectionViewSectionedReloadDataSource<MyPageSectionModel>(
            configureCell: { dataSource, collectionView, indexPath, item in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "listCell", for: indexPath) as! UICollectionViewListCell
                
                var background = UIBackgroundConfiguration.listPlainCell()
                background.backgroundColor = .appDarkGray
                cell.backgroundConfiguration = background
                
                var content = cell.defaultContentConfiguration()
                let imageConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
                content.image = UIImage(systemName: item.iconName, withConfiguration: imageConfig)
                content.imageProperties.tintColor = AppColor.appWhite
                
                content.attributedText = NSAttributedString(string: item.title, attributes: [
                    .font: AppFont.semiboldSubTitle,
                    .foregroundColor: AppColor.appWhite
                ])
                content.secondaryAttributedText = NSAttributedString(string: item.detailText ?? "", attributes: [
                    .font: AppFont.callout,
                    .foregroundColor: AppColor.appWhite
                ])
                cell.contentConfiguration = content
                cell.accessories = [.disclosureIndicator()]
                
                return cell
            }, configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                guard kind == UICollectionView.elementKindSectionHeader else {
                    return UICollectionReusableView()
                }
                
                guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MyPageHeaderView.reusableID, for: indexPath) as? MyPageHeaderView else { return UICollectionReusableView() }
                
                let section = dataSource.sectionModels[indexPath.section]
                headerView.configureUI(header: section.header)
                
                return headerView
            }
        )
        
        reactor.state.map { $0.sections }
            .bind(to: myPageCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$selectedMyPageSection)
            .compactMap { $0 }
            .bind(with: self) { owner, section in
                owner.moveSection(section)
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$updateSection)
            .compactMap { $0 }
            .bind(with: self) { owner, _ in
                owner.myPageCollectionView.reloadData()
            }
            .disposed(by: disposeBag)
    }
    
    private func bindAction(_ reactor: MyPageReactor) {
        self.rx.methodInvoked(#selector(viewDidLoad))
            .map { _ in Reactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.rx.methodInvoked(#selector(viewWillAppear))
            .map { _ in Reactor.Action.updateSections }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        myPageCollectionView.rx.itemSelected
            .map { Reactor.Action.itemSelected($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func moveSection(_ item: MyPageSectionItem) {
        switch item {
        case .reviews, .watchlist, .watchHistory, .isStared:
            let reactor = SavedMediaReactor(item.sectionType, mediaDBManager: self.mediaDBManager)
            let vc = SavedMediaViewController(networkService: self.networkService, imageProvider: self.imageProvider, mediaDBManager: self.mediaDBManager, reviewDBManager: self.reviewDBManager)
            vc.reactor = reactor
            vc.updateSections = { [weak self] in
                guard let self = self else { return }
                self.reactor?.action.onNext(.updateSections)
            }
            
            self.navigationController?.pushViewController(vc, animated: true)
            
        case .appInfo:
            print("앱 정보 화면으로 이동")
        }
    }
}
