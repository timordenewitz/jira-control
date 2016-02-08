//
//  ViewController.swift
//  JIRA Commander
//
//  Created by Tim Ordenewitz on 05.02.16.
//  Copyright © 2016 Tim Ordenewitz. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var UserTextField: UITextField!
    @IBOutlet var PWTextField: UITextField!
    @IBOutlet var ServerAdressTextField: UITextField!
    
    var base64EncodedAuth :String = ""
    var username :String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        prepareTextFields()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        UIApplication.sharedApplication().sendAction("resignFirstResponder", to:nil, from:nil, forEvent:nil)
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func prepareTextFields() {
        UserTextField.attributedPlaceholder = NSAttributedString(string:"USERNAME",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        UserTextField.delegate = self
        
        PWTextField.attributedPlaceholder = NSAttributedString(string:"PASSWORD",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        PWTextField.delegate = self
        
        ServerAdressTextField.attributedPlaceholder = NSAttributedString(string:"SERVER ADRESS",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        ServerAdressTextField.delegate = self
    }
    
    @IBAction func loginButtonClicked(sender: AnyObject) {
        let pw = PWTextField.text
        username = UserTextField.text!
        let auth = pw! + ":" + username
        let utf8auth = auth.dataUsingEncoding(NSUTF8StringEncoding)
        base64EncodedAuth = (utf8auth?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)))!
        
        //Send Request
        Alamofire.request(.GET, "http://46.101.221.171:8080/rest/api/latest/search?jql=reporter=" + username, headers: ["Authorization" : "Basic " + base64EncodedAuth])
            .responseJSON { response in
                if let JSON = response.result.value {
                    if let issues = JSON["issues"] {
                        //All Issues Reported by User
                        for var index = 0; index < issues!.count; ++index{
                        }
                    }
                }
                
//                if let statusCode = response.response?.statusCode {
//                    if (statusCode == 200) {
//                        self.performDashboardSegue()
//                    }
//                }
                self.performDashboardSegue()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let theDestination = (segue.destinationViewController as! DashboardViewController)
        theDestination.authBase64 =  base64EncodedAuth
        theDestination.serverAdress =  ServerAdressTextField.text!
        theDestination.username =  username
        
    }
    
    func performDashboardSegue() {
        performSegueWithIdentifier("showDashboardSegue", sender: self)
    }
}

