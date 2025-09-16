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
import FirebaseAnalytics

final class MediaTierListViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    
    private lazy var tierListCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .mediaTierListLayout).then {
        $0.backgroundColor = .clear
        $0.register(PosterCollectionViewCell.self, forCellWithReuseIdentifier: PosterCollectionViewCell.cellID)
        $0.register(TierSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TierSectionHeaderView.reusableID)
        $0.dragDelegate = self
        $0.dropDelegate = self
        $0.dragInteractionEnabled = true
    }
    private let imageProvider: ImageProviding
    private let imageFileManager: ImageFileManaging
    
    init(imageProvider: ImageProviding, imageFileManager: ImageFileManaging) {
        self.imageProvider = imageProvider
        self.imageFileManager = imageFileManager
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
        view.addSubview(tierListCollectionView)
    }
    
    private func configureLayout() {
        tierListCollectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func configureNavigationBar() {
        let appIconView = UIView()
        let label = UILabel()
        label.font = AppFont.boldLargeTitle
        label.text = "나의 티어리스트"
        label.textColor = AppColor.appWhite
        
        let image = UIImage(systemName: "sunglasses")
        let imageView = UIImageView(image: image)
        imageView.tintColor = .appRed
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
    
    func bind(reactor: MediaTierListReactor) {
//        self.rx.methodInvoked(#selector(viewDidLoad))
//            .map { _ in Reactor.Action.viewDidLoad }
//            .bind(to: reactor.action)
//            .disposed(by: disposeBag)
        
        reactor.action.onNext(.viewDidLoad)
        
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
                
                cell.reactor = PosterCollectionViewCellReactor(media: media, imageProvider: self.imageProvider, imageFileManager: self.imageFileManager)
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
        
        reactor.state.map { $0.sections }
            .do (onNext: { [weak self] sectionModels in
                guard let unrankedItemsCount = sectionModels.last?.items else { return }
                DispatchQueue.main.async {
                    if unrankedItemsCount.isEmpty {
                        self?.tierListCollectionView.contentInset.bottom = 50
                    } else {
                        self?.tierListCollectionView.contentInset.bottom = 0
                    }
                }
            })
            .bind(to: tierListCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        self.rx.methodInvoked(#selector(viewWillAppear))
            .do(onNext: { _ in
                Analytics.logEvent("MediaTierListViewController_Appeared", parameters: nil)
            })
            .map { _ in Reactor.Action.updateSavedMedia }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
}

extension MediaTierListViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let itemProvider = NSItemProvider(object: "\(indexPath.section),\(indexPath.row)" as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return nil
        }
        
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        
        let cornerRadius: CGFloat = 12.0
        let visiblePath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cornerRadius)
        
        parameters.visiblePath = visiblePath
        
        return parameters
    }
}

extension MediaTierListViewController: UICollectionViewDropDelegate {
    // 사용자가 드래그 중인 아이템이 화면 위에서 움직일 때 반복적으로 호출
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: any UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard session.localDragSession != nil else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    // 최종적으로 drop을 했을 때 호출
    // coordinator: drop에 대한 모든 정보와 최종 액션을 설정할 수 있는 객체
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        // coordinator.items.first: 드래그한 첫번째 셀
        // sourceIndexPath: 드래그한 셀에 대한 indexPath
        guard let sourceIndexPath = coordinator.items.first?.sourceIndexPath else { return }
        
        // 도착한 indexPath
        guard let destinationIndexPath = self.destinationIndexPath(session: coordinator.session, collectionView: collectionView) else { return }
        
        var finalDestinationIndexPath = destinationIndexPath
        // 만약 해당 섹션에 아이템이 없는 경우
        // 해당 섹션의 첫번째인 indexPath로 값 설정
        if collectionView.numberOfItems(inSection: destinationIndexPath.section) == 0 {
            finalDestinationIndexPath = IndexPath(row: 0, section: destinationIndexPath.section)
        }
        
        // 시작점과 종착점 전달
        self.reactor?.action.onNext(.moveItem(from: sourceIndexPath, to: finalDestinationIndexPath))
        Analytics.logEvent("SetTierList", parameters: nil)
    }
    
    // 빈 티어 섹션에 미디어를 두는 경우에 대해 section과 row를을 계산하여 indexPath를 전달
    private func destinationIndexPath(session: UIDropSession, collectionView: UICollectionView) -> IndexPath? {
        let dropPoint = session.location(in: collectionView)
        // 1) 빈공간이 아닌 섹션에 두는 경우(만약 collectionView.indexPathForItem로 파악가능한 경우)
        // 바로 indexPath를 리턴
        if let indexPath = collectionView.indexPathForItem(at: dropPoint) {
            return indexPath
        }

        var section = -1
        
        // 섹션을 순회하여 미디어를 둔 섹션을 찾는 과정 진행
        for i in (0..<collectionView.numberOfSections).reversed() {
            // 현재 순회 중인 섹션의 헤더 위치 정보를 가져옵니다.
            guard let headerAttributes = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: i)) else {
                continue
            }
            
            // 드롭된 지점의 Y 좌표가 현재 헤더의 시작 Y 좌표보다 크거나 같다면,
            // 이 섹션 또는 그 이후 섹션에 드롭된 것입니다.
            // 거꾸로 순회했으므로, 가장 먼저 이 조건을 만족하는 섹션이 바로 목표 섹션입니다.
            if dropPoint.y >= headerAttributes.frame.minY {
                section = i
                break
            }
        }
        
        // 섹션이 -1이 아닌 경우
        // 해당 섹션과 item의 indexPath를 리턴
        if section != -1 {
            let itemCount = collectionView.numberOfItems(inSection: section)
            return IndexPath(item: itemCount, section: section)
        }
        // dropPoint를 포함하는 섹션을 찾지 못했다면
        // nil 리턴
        return nil
    }
}
