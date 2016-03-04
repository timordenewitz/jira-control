//
//  AppDelegate.swift
//  JIRA Commander
//
//  Created by Tim Ordenewitz on 05.02.16.
//  Copyright © 2016 Tim Ordenewitz. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import Appsee
import QorumLogs

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let defaults = NSUserDefaults.standardUserDefaults()
    var window: UIWindow?
    
    enum defaultsKeys {
        static let usernameKey = "de.scandio.jira-commander.username"
        static let pwKey = "de.scandio.jira-commander.password"
        static let serverAdressKey = "de.scandio.jira-commander.server"
        static let saveLogin = "de.scandio.jira-commander.save-login"
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.    UINavigationBar.appearance().setBackgroundImage(UIImage(), forBarMetrics: .Default)
        Fabric.with([Crashlytics.self, Appsee.self])
        UISearchBar.appearance().barTintColor = UIColor.whiteColor()
        UISearchBar.appearance().tintColor = UIColor.blackColor()
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).tintColor = UIColor.whiteColor()
        quorumLogInit()
        return true
    }
    
    func quorumLogInit() {
        QorumOnlineLogs.setupOnlineLogs(formLink: "https://docs.google.com/forms/d/1m-Zm4WNejE2gQa8DnnDE8aR07FTOzlBBcJgHX-eGO78/formResponse", versionField: "entry_935409", userInfoField: "entry_279656771", methodInfoField: "entry_492594094", textField: "entry_453397443", forceField: "entry_1326940741", targetForceField: "entry_1507533875", userAgeField: "entry_1132471491", userHandedField: "entry_1377018990", used3DTouchField: "entry_302073775", uuidField: "entry_2127357423", numberOfExperimentsPassedField: "entry_1992293764", matchedTargetValueField: "entry_1856907095", touchArrayField: "entry_425307947")
        QorumLogs.enabled = false // This should be disabled for OnlineLogs to work
        QorumOnlineLogs.enabled = true
    }


    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        if let saveLogin = defaults.stringForKey(defaultsKeys.saveLogin) {
            if(!saveLogin.boolValue) {
                defaults.setValue(nil, forKey: defaultsKeys.pwKey)
                defaults.setValue(nil, forKey: defaultsKeys.usernameKey)
                defaults.synchronize()
            }
        }
    }
}

