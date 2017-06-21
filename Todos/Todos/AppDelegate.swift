//
//  AppDelegate.swift
//  Todos
//
//  Created by Chris Eidhof on 21.06.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import UIKit
import  TodosFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
//    let driver = Driver(EmptyApp())
//    let driver = Driver(GifApp())
    let driver = Driver(TodosApp())
    


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = driver.viewController
        window?.makeKeyAndVisible()
        window?.backgroundColor = .white
        
        return true
    }

}

