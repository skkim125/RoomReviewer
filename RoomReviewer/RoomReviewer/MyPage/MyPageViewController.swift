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
    }
    
    var disposeBag = DisposeBag()
    
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
            $0.edges.equalToSuperview()
        }
    }
    
    private func configureNavigationBar() {
        let label = UILabel()
        label.font = AppFont.appIconTitle
        label.text = "마이 페이지"
        label.textColor = AppColor.appWhite
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: label)
    }
    
    func bind(reactor: MyPageReactor) {
        bindState(reactor)
        bindAction(reactor)
    }
    
    private func bindState(_ reactor: MyPageReactor) {
        let dataSource = RxCollectionViewSectionedReloadDataSource<MyPageSectionModel>(
            configureCell: { dataSource, collectionView, indexPath, item in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "listCell", for: indexPath) as! UICollectionViewListCell
                
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
        
        reactor.state
            .map { $0.sections }
            .bind(to: myPageCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$selectedMyPageSection)
            .compactMap { $0 }
            .bind(with: self) { owner, section in
                owner.moveSection(section)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindAction(_ reactor: MyPageReactor) {
        self.rx.methodInvoked(#selector(viewDidLoad))
            .map { _ in
                Reactor.Action.viewDidLoad
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        myPageCollectionView.rx.itemSelected
            .map { Reactor.Action.itemSelected($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func moveSection(_ item: MyPageSectionItem) {
        switch item {
        case .reviews:
            print("나의 평론 화면으로 이동")
        case .watchlist:
            print("보고싶어요 화면으로 이동")
        case .watchHistory:
            print("내가 본 작품 화면으로 이동")
        case .appInfo:
            print("앱 정보 화면으로 이동")
        }
    }
}
