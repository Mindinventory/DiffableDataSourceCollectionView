//
//  AppDelegate.swift
//  DiffableDataSourceCollectionView
//
//  Created by mac-00010 on 10/11/2020.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window?.frame = UIScreen.main.bounds
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ViewController")
        window?.rootViewController = vc
        window?.makeKeyAndVisible()

        return true
    }
}

