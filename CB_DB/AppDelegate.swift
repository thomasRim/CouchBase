//
//  AppDelegate.swift
//  CB_DB
//
//  Created by Vladimir Yevdokimov on 20.11.2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        subscribeNotifications()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    private func subscribeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didLogin), name: Notification.Name.authLoginSuccessful, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didLogout), name: Notification.Name.authLogoutSuccessful, object: nil)
    }
    
    @objc private func didLogin() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        UIApplication.shared.windows.first?.rootViewController = vc
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    @objc private func didLogout() {
        let vc = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController()
        UIApplication.shared.windows.first?.rootViewController = vc
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
}

