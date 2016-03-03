//
//  SettingsViewController.swift
//  JIRA Commander
//
//  Created by Tim Ordenewitz on 08.02.16.
//  Copyright © 2016 Tim Ordenewitz. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    var saveLoginInfo = false
    let defaults = NSUserDefaults.standardUserDefaults()

    enum defaultsKeys {
        static let usernameKey = "de.scandio.jira-commander.username"
        static let pwKey = "de.scandio.jira-commander.password"
        static let serverAdressKey = "de.scandio.jira-commander.server"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @IBAction func logoutButtonClicked(sender: AnyObject) {
        if(!saveLoginInfo){
            defaults.setValue(nil, forKey: defaultsKeys.pwKey)
            defaults.setValue(nil, forKey: defaultsKeys.usernameKey)
            defaults.synchronize()
        }
    }
}
