//
//  SceneDelegate.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/5/25.
//

import UIKit
import RxSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var networkMonitor: NetworkMonitoring?
    private var disposeBag = DisposeBag()


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        
        let networkMonitor = NetworkMonitor()
        self.networkMonitor = networkMonitor
        networkMonitor.start()
        
        let mainTabBarController = setupTabBarController(networkMonitor: networkMonitor)
        
        window?.rootViewController = mainTabBarController
        window?.makeKeyAndVisible()
    }
    
    private func setupTabBarController(networkMonitor: NetworkMonitoring) -> UITabBarController {
        let tabBarController = MainTabBarController(networkMonitor: networkMonitor)
        
        let dataFetcher = URLSessionDataFetcher(networkMonitor: networkMonitor)
        let networkManager = NetworkManager(dataFetcher: dataFetcher)
        let imageStore: ImageFileManaging = ImageFileManager()
        let imageProvider = ImageProvider(dataFetcher: dataFetcher)
        let dataStack = CoreDataStack(modelName: "RoomReviewerEntity")
        let mediaDatabaseManager = MediaDatabaseManager(stack: dataStack)
        let reviewDatabaseManager = ReviewDatabaseManager(stack: dataStack)
        
        let homeReactor = HomeReactor(networkService: networkManager, mediaDBManager: mediaDatabaseManager, networkMonitor: networkMonitor)
        let homeVC = HomeViewController(imageProvider: imageProvider, imageFileManager: imageStore, mediaDBManager: mediaDatabaseManager, reviewDBManager: reviewDatabaseManager, networkManager: networkManager, networkMonitor: networkMonitor)
        homeVC.reactivateOnlineUIMode = { [weak tabBarController] in
            tabBarController?.reactivateOnlineUI()
        }
        homeVC.reactor = homeReactor
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.delegate = tabBarController
        homeNav.tabBarItem.image = UIImage(systemName: "house")
        homeNav.title = "홈"
        
        let tierListReactor = MediaTierListReactor(mediaDBManager: mediaDatabaseManager)
        let tierListVC = MediaTierListViewController(imageProvider: imageProvider, imageFileManager: imageStore)
        tierListVC.reactor = tierListReactor
        let tierListNav = UINavigationController(rootViewController: tierListVC)
        tierListNav.delegate = tabBarController
        tierListNav.tabBarItem.image = UIImage(systemName: "list.number")
        tierListNav.title = "티어"
        
        let mypageReactor = MyPageReactor(mediaDBManager: mediaDatabaseManager)
        let myPageVC = MyPageViewController(imageProvider: imageProvider, imageFileManager: imageStore, mediaDBManager: mediaDatabaseManager, reviewDBManager: reviewDatabaseManager, networkManager: networkManager, networkMonitor: networkMonitor)
        myPageVC.reactor = mypageReactor
        let myPageNav = UINavigationController(rootViewController: myPageVC)
        myPageNav.delegate = tabBarController
        myPageNav.tabBarItem.image = UIImage(systemName: "ellipsis")
        myPageNav.title = "더보기"
        
        tabBarController.viewControllers = [
            homeNav,
            tierListNav,
            myPageNav
        ]
        
        tabBarController.tabBar.tintColor = AppColor.appWhite
        tabBarController.tabBar.unselectedItemTintColor = AppColor.appGray
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColor.appBackgroundColor
        
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance

        return tabBarController
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

