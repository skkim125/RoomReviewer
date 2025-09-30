//
//  CreditListViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/30/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import RxDataSources
import Then
import SnapKit

final class CreditListViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    
    private let backButton = UIBarButtonItem().then {
        $0.image = UIImage(systemName: "chevron.left")
        $0.tintColor = AppColor.appWhite
        $0.style = .done
        $0.target = nil
        $0.action = nil
    }
    
    private var creditListCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .creditListCollectionViewLayout).then {
        $0.register(CreditListCollectionViewCell.self, forCellWithReuseIdentifier: CreditListCollectionViewCell.cellID)
        $0.register(CreditsSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CreditsSectionHeader.reusableID)
    }
    
    private let imageProvider: ImageProviding
    
    init(imageProvider: ImageProviding) {
        self.imageProvider = imageProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureLayout()
        configureNavigationBar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureHierarchy() {
        view.addSubview(creditListCollectionView)
    }
    
    private func configureLayout() {
        creditListCollectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func bind(reactor: CreditListReactor) {
        self.rx.methodInvoked(#selector(viewDidLoad))
            .map { _ in Reactor.Action.viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<CreditListSectionModel>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item in
                guard let self = self,
                      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreditListCollectionViewCell.cellID, for: indexPath) as? CreditListCollectionViewCell else {
                    return UICollectionViewListCell()
                }
                
                switch item {
                case .cast(let cast):
                    cell.reactor = CreditListCollectionViewCellReactor(name: cast.name, role: cast.character, profilePath: cast.profilePath, imageLoader: self.imageProvider)
                }
                
                return cell
            }
        )
        
        reactor.state.map { $0.sections }
            .bind(to: creditListCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        backButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func configureNavigationBar() {
        navigationItem.title = "모든 출연진"
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = backButton
    }
}
