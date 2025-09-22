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
import FirebaseAnalytics
import MessageUI

final class MyPageViewController: UIViewController, View {
    private var myPageCollectionView = UICollectionView(frame: .zero, collectionViewLayout: .myPageCollectionViewLayout).then {
        $0.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "listCell")
        $0.register(MyPageHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MyPageHeaderView.reusableID)
        $0.backgroundColor = .clear
    }
    
    var disposeBag = DisposeBag()
    
    private let imageProvider: ImageProviding
    private let imageFileManager: ImageFileManaging
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    private let networkManager: NetworkService
    private let networkMonitor: NetworkMonitoring
    
    init(imageProvider: ImageProviding, imageFileManager: ImageFileManaging, mediaDBManager: MediaDBManager, reviewDBManager: ReviewDBManager, networkManager: NetworkService, networkMonitor: NetworkMonitoring) {
        self.imageProvider = imageProvider
        self.imageFileManager = imageFileManager
        self.mediaDBManager = mediaDBManager
        self.reviewDBManager = reviewDBManager
        self.networkManager = networkManager
        self.networkMonitor = networkMonitor
        
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
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(20)
        }
    }
    
    private func configureNavigationBar() {
        let appIconView = UIView()
        let label = UILabel()
        label.font = AppFont.appIconTitle
        label.text = "더보기"
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
        
        if #available(iOS 26, *) {
            navigationItem.titleView = appIconView
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: appIconView)
        }
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Analytics.logEvent("MyPageView_Appeared", parameters: nil)
    }
    
    private func moveSection(_ item: MyPageSectionItem) {
        switch item {
        case .reviews(let medias), .watchlist(let medias), .watchHistory(let medias), .isStared(let medias):
            let reactor = SavedMediaReactor(medias: medias, item.sectionType, mediaDBManager: self.mediaDBManager)
            let vc = SavedMediaViewController(imageProvider: self.imageProvider, imageFileManager: self.imageFileManager, mediaDBManager: self.mediaDBManager, reviewDBManager: self.reviewDBManager, networkManager: self.networkManager, networkMonitor: self.networkMonitor)
            vc.reactor = reactor
            vc.updateSections = { [weak self] in
                guard let self = self else { return }
                self.reactor?.action.onNext(.updateSections)
            }
            
            self.navigationController?.pushViewController(vc, animated: true)
            
        case .appInfo:
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
            let appIcon = UIImage(named: "appIconImage")
            
            let infoView = UIView()
            let iconImageView = UIImageView(image: appIcon)
            iconImageView.tintColor = AppColor.appWhite
            iconImageView.layer.cornerRadius = 12
            iconImageView.clipsToBounds = true
            
            let versionLabel = UILabel()
            versionLabel.text = "버전 정보: \(version)"
            versionLabel.font = AppFont.subTitle
            versionLabel.textColor = AppColor.appWhite
            versionLabel.textAlignment = .center
            
            infoView.addSubview(iconImageView)
            infoView.addSubview(versionLabel)
            
            iconImageView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.centerX.equalToSuperview()
                make.width.height.equalTo(80)
            }
            
            versionLabel.snp.makeConstraints { make in
                make.top.equalTo(iconImageView.snp.bottom).offset(10)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview().inset(10)
            }
            
            let alert = CustomAlertViewController(
                title: "앱 정보",
                buttonType: .oneButton,
                contentView: infoView
            )
            self.present(alert, animated: true)
            
        case .contactUs:
            showEmailActionSheet()
        }
    }
    
    private func showEmailActionSheet() {
        let actionSheet = UIAlertController(title: "문의하기", message: "사용할 메일 앱을 선택해주세요.", preferredStyle: .actionSheet)
        
        let mailAction = UIAlertAction(title: "Mail 앱", style: .default) { [weak self] _ in
            self?.sendEmailWithDefaultMailApp()
        }
        
        let gmailAction = UIAlertAction(title: "Gmail", style: .default) { [weak self] _ in
            self?.sendEmailWithGmail()
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        actionSheet.addAction(mailAction)
        actionSheet.addAction(gmailAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true)
    }
    
    private func sendEmailWithDefaultMailApp() {
        if MFMailComposeViewController.canSendMail() {
            let email = Bundle.main.infoDictionary?["My_Email"] as? String ?? ""
            let mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = self
            
            mailVC.setToRecipients([email])
            mailVC.setSubject("[방구석 평론가] 문의하기")
            mailVC.setMessageBody(emailBodyContent(), isHTML: false)
            
            self.present(mailVC, animated: true)
        } else {
            showMailAppNotAvailableAlert(appName: "Mail")
        }
    }
    
    private func sendEmailWithGmail() {
        let email = Bundle.main.infoDictionary?["My_Email"] as? String ?? ""
        let subject = "[방구석 평론가] 문의하기".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = emailBodyContent().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let gmailURL = URL(string: "googlegmail:///co?to=\(email)&subject=\(subject)&body=\(body)"),
           UIApplication.shared.canOpenURL(gmailURL) {
            UIApplication.shared.open(gmailURL, options: [:], completionHandler: nil)
        } else {
            showMailAppNotAvailableAlert(appName: "Gmail")
        }
    }
    
    private func showMailAppNotAvailableAlert(appName: String) {
        let message = appName == "Mail" ? "이메일을 보내려면 기기의 '메일' 앱에서 계정을 설정해주세요." : "Gmail 앱이 설치되어 있지 않습니다."
        let alert = CustomAlertViewController(
            title: "메일 계정 없음",
            subtitle: message,
            buttonType: .oneButton
        )
        self.present(alert, animated: true)
    }
    
    private func emailBodyContent() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        let osVersion = UIDevice.current.systemVersion
        
        return """
            
            -------------------
            - App Version: \(appVersion)
            - OS Version: \(osVersion)
            - Device: (사용 기종을 적어주세요)
            -------------------
            
            버그 제보나 문의하실 내용을 여기에 작성해주세요.
            
            """
    }
}

extension MyPageViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
