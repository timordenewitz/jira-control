//
//  DashboardViewController.swift
//  JIRA Commander
//
//  Created by Tim Ordenewitz on 05.02.16.
//  Copyright © 2016 Tim Ordenewitz. All rights reserved.
//

import UIKit

class DashboardViewController: UIViewController {
    
    var authBase64 :String = ""
    var serverAdress : String = ""
    var username : String = ""
    
    let chartQuickIcon = UIApplicationShortcutIcon(templateImageName: "QuickChartIcon")
    let stressQuickIcon = UIApplicationShortcutIcon(templateImageName: "QuickStressIcon")
    let priorityQuickIcon = UIApplicationShortcutIcon(templateImageName: "QuickPriorityIcon")

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        // Do any additional setup after loading the view.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
    }
    
    override func viewDidAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)

    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let backItem = UIBarButtonItem()
        backItem.title = ""
        UINavigationBar.appearance().tintColor = UIColor.blackColor()
        navigationItem.backBarButtonItem = backItem
        
        if (segue.identifier == "PressureWeight"){
            let theDestination = (segue.destinationViewController as! PressureWeightViewController)
            theDestination.authBase64 =  authBase64
            theDestination.serverAdress =  serverAdress
            theDestination.username =  username
        }
        
        if (segue.identifier == "StressTicketSegue"){
            let theDestination = (segue.destinationViewController as! StressTicketViewController)
            theDestination.authBase64 =  authBase64
            theDestination.serverAdress =  serverAdress
            theDestination.username =  username
        }
        
        if (segue.identifier == "DiagramSegue"){
            let theDestination = (segue.destinationViewController as! DiagramViewController)
            theDestination.authBase64 =  authBase64
            theDestination.serverAdress =  serverAdress
        }
    }
}
