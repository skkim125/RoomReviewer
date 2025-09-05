//
//  SceneDelegate.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/5/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        
        window?.rootViewController = setupVC()
        window?.makeKeyAndVisible()
    }
    
    private func setupVC() -> UITabBarController {
        let tabBarController = UITabBarController()
        let networkManager = NetworkManager()
        let imageProvider = ImageProvider()
        let dataStack = CoreDataStack(modelName: "RoomReviewerEntity")
        let mediaDatabaseManager = MediaDatabaseManager(stack: dataStack)
        let reviewDatabaseManager = ReviewDatabaseManager(stack: dataStack)
        
        let homeReactor = HomeReactor(networkService: networkManager, mediaDBManager: mediaDatabaseManager)
        let homeVC = HomeViewController(imageProvider: imageProvider, mediaDBManager: mediaDatabaseManager, reviewDBManager: reviewDatabaseManager)
        homeVC.reactor = homeReactor
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeVC.tabBarItem.image = UIImage(systemName: "house")
        
        let searchReactor = SearchMediaReactor(networkService: networkManager)
        let searchVC = SearchMediaViewController(imageProvider: imageProvider, mediaDBManager: mediaDatabaseManager, reviewDBManager: reviewDatabaseManager)
        searchVC.reactor = searchReactor
        let searchNav = UINavigationController(rootViewController: searchVC)
        searchNav.tabBarItem.image = UIImage(systemName: "magnifyingglass")
        
//        let tierVC = UIViewController()
//        let tierNav = UINavigationController(rootViewController: tierVC)
//        tierNav.tabBarItem.image = UIImage(systemName: "list.triangle")
//        tierNav.tabBarItem.title = "티어표"
        
        let mypageReactor = MyPageReactor(mediaDBManager: mediaDatabaseManager)
        let myPageVC = MyPageViewController(networkService: networkManager,imageProvider: imageProvider, mediaDBManager: mediaDatabaseManager, reviewDBManager: reviewDatabaseManager)
        myPageVC.reactor = mypageReactor
        let myPageNav = UINavigationController(rootViewController: myPageVC)
        myPageNav.tabBarItem.image = UIImage(systemName: "ellipsis")
        
        tabBarController.viewControllers = [
            homeNav,
            searchNav,
//            tierNav,
            myPageNav
        ]
        
        tabBarController.tabBar.tintColor = AppColor.appWhite
        tabBarController.tabBar.unselectedItemTintColor = AppColor.appGray

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

