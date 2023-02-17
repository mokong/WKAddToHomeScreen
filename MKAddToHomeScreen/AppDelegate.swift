//
//  AppDelegate.swift
//  MKAddToHomeScreen
//
//  Created by MorganWang on 2021/4/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.white

        self.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func targetViewController(from path: String) -> UIViewController? {
        var targetVC: UIViewController?
        switch path {
        // 根据URL的path跳转不同路径
        case "/view1":
            targetVC = Method1ViewController()
            break
        case "/view2":
            targetVC = Method2ViewController()
            break
        case "/view3":
            targetVC = Method3ViewController()
            break
        default:
            targetVC = nil
            break
        }
        return targetVC
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let navController = window?.rootViewController as? UINavigationController,
            let topController = navController.topViewController {
            // eg: mkaddtohomescreen://page/view1
            // url.host = page
            // url.path = /view1
            if url.absoluteString.hasPrefix("mkaddtohomescreen://") {
                // 说明是APP的URL Scheme，处理
                
                let targetVC = targetViewController(from: url.path)
                if targetVC != nil {
                    // 判断当前显示的界面是否是要跳转的界面
                    if topController.classForCoder == targetVC?.classForCoder {
                        return true
                    }
                    
                    navController.pushViewController(targetVC!, animated: true)
                }
                else {
                    return true
                }
            }
        }
        return true
    }

}

