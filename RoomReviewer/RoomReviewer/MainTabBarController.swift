//
//  MainTabBarController.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/16/25.
//

import UIKit
import RxSwift
import GoogleMobileAds
import SnapKit
import AppTrackingTransparency

final class MainTabBarController: UITabBarController {
    private let networkMonitor: NetworkMonitoring
    private var disposeBag = DisposeBag()
    
    private lazy var bannerView = BannerView().then {
        $0.adSize = AdSizeBanner
        $0.adUnitID = Bundle.main.object(
            forInfoDictionaryKey: "GAD_BannerADs_Identifier"
        ) as? String ?? ""
        $0.rootViewController = self
        $0.isHidden = true
    }
    
    private var isBannerAdLoaded = false
    
    init(networkMonitor: NetworkMonitoring) {
        self.networkMonitor = networkMonitor
        super.init(nibName: nil, bundle: nil)
        
        bindNetwork()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
//        loadBannerView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestIDFA()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isBannerAdLoaded {
            let viewWidth = view.frame.inset(by: view.safeAreaInsets).width
            bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
        }
    }
    
    private func bindNetwork() {
        networkMonitor.isConnected
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, isConnected in
                if !isConnected {
                    owner.updateBannerState()
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func loadBannerView() {
        view.addSubview(bannerView)
        setupBannerLayout()
        bannerView.delegate = self
        bannerView.load(Request())
    }

    private func setupBannerLayout() {
        bannerView.snp.makeConstraints { make in
            make.bottom.equalTo(self.tabBar.snp.top)
            make.centerX.equalToSuperview()
        }
    }
    
    func reactivateOnlineUI() {
        updateBannerState()
    }
    
    private func updateBannerState() {
        guard let navController = self.selectedViewController as? UINavigationController else { return }
        
        let isRootVC = navController.viewControllers.count == 1
        let isConnected = networkMonitor.isCurrentlyConnected
        
        if isBannerAdLoaded && isRootVC && isConnected {
            bannerView.isHidden = false
        } else {
            bannerView.isHidden = true
        }
        
        adjustContentInsets()
    }
    
    private func adjustContentInsets() {
        guard let navController = self.selectedViewController as? UINavigationController,
              let contentVC = navController.topViewController else { return }
        
        if isBannerAdLoaded && !bannerView.isHidden {
            contentVC.additionalSafeAreaInsets.bottom = bannerView.frame.height
        } else {
            contentVC.additionalSafeAreaInsets.bottom = 0
        }
    }
    
    private func requestIDFA() {
        if #available(iOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                
            }
        }
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateBannerState() // 탭 변경 시 상태 업데이트
    }
}

extension MainTabBarController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        updateBannerState() // Push/Pop 시 상태 업데이트
    }
}

extension MainTabBarController: BannerViewDelegate {
    /// 광고 수신에 성공했을 때 호출됩니다.
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("광고 수신 성공")
        isBannerAdLoaded = true
        // 현재 보이는 뷰가 루트 뷰일 때만 배너를 보여줍니다. (push된 상태에서 광고가 로드될 수 있으므로)
        if let navController = selectedViewController as? UINavigationController, navController.viewControllers.count == 1 {
            bannerView.isHidden = false
        }
        adjustContentInsets()
    }

    /// 광고 수신에 실패했을 때 호출됩니다.
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("광고 수신 실패: \(error.localizedDescription)")
        isBannerAdLoaded = false
        bannerView.isHidden = true
        adjustContentInsets()
    }
}
