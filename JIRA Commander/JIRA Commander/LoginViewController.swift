//
//  ViewController.swift
//  JIRA Commander
//
//  Created by Tim Ordenewitz on 05.02.16.
//  Copyright © 2016 Tim Ordenewitz. All rights reserved.
//

import UIKit
import Alamofire
import OnePasswordExtension

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var UserTextField: UITextField!
    @IBOutlet var PWTextField: UITextField!
    @IBOutlet var ServerAdressTextField: UITextField!
    @IBOutlet weak var onePasswordButton: UIButton!
    @IBOutlet weak var saveLoginSwitch: UISwitch!
    
    var authBase64 :String = ""
    var username :String = ""
    var serverAdress : String = ""
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    enum defaultsKeys {
        static let usernameKey = "de.scandio.jira-commander.username"
        static let pwKey = "de.scandio.jira-commander.password"
        static let serverAdressKey = "de.scandio.jira-commander.server"
        static let saveLogin = "de.scandio.jira-commander.save-login"
    }
    
    let testJiraUrl = "http://46.101.221.171:8080"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        prepareTextFields()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        if let username = defaults.stringForKey(defaultsKeys.usernameKey) {
            UserTextField.text = username
        }
        
        if let pw = defaults.stringForKey(defaultsKeys.pwKey) {
            PWTextField.text = pw
        }
        if let serverAdress = defaults.stringForKey(defaultsKeys.serverAdressKey) {
            ServerAdressTextField.text = serverAdress
        }
        if let saveLogin = defaults.stringForKey(defaultsKeys.saveLogin) {
            saveLoginSwitch.on = saveLogin.boolValue
        }
        
        onePasswordButton.hidden = true
        if (OnePasswordExtension.sharedExtension().isAppExtensionAvailable()) {
            onePasswordButton.hidden = false
        }
    }
    
    @IBAction func passwordButtonClicked(sender: AnyObject) {
        OnePasswordExtension.sharedExtension().findLoginForURLString("Jira Commander", forViewController: self, sender: sender, completion: { (loginDictionary, error) -> Void in
            if loginDictionary == nil {
                if error!.code != Int(AppExtensionErrorCodeCancelledByUser) {
                    print("Error invoking 1Password App Extension for find login: \(error)")
                }
                return
            }
            self.UserTextField.text = loginDictionary?[AppExtensionUsernameKey] as? String
            self.PWTextField.text = loginDictionary?[AppExtensionPasswordKey] as? String
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        UIApplication.sharedApplication().sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, forEvent:nil)
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
        let pw = PWTextField.text!
        print("clicked")
        username = UserTextField.text!
        let auth = pw + ":" + username
        let utf8auth = auth.dataUsingEncoding(NSUTF8StringEncoding)
        authBase64 = (utf8auth?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)))!
        serverAdress = ServerAdressTextField.text!
        
        let parameters = [
            "username": username,
            "password" : pw
        ]
        

        //Send Request
        Alamofire.request(.POST, serverAdress + "/rest/auth/1/session" , headers: ["Content-Type" : "application/json"], parameters: ["username" : "tordenewitz", "password" : "i4NwKXqdxcw8xotH"], encoding: .JSON)
            .responseJSON { response in
                print(response.result)
                print(response.request?.HTTPBodyStream)
                print(response.request?.HTTPBodyStream)
                print(response.request?.allHTTPHeaderFields)
                print(response.request)
                print(response.response)
                if (response.response == nil) {
                    self.showLoginAlert(" Please enable your network connection.")
                }

                if (self.saveLoginSwitch.on) {
                    self.defaults.setValue(pw, forKey: defaultsKeys.pwKey)
                    self.defaults.setValue(self.username, forKey: defaultsKeys.usernameKey)
                }
                self.defaults.setValue(self.serverAdress, forKey: defaultsKeys.serverAdressKey)
                self.defaults.setValue(self.saveLoginSwitch.on, forKey: defaultsKeys.saveLogin)
                self.defaults.synchronize()
                if let statusCode = response.response?.statusCode {
                    if (statusCode == 200) {
                        self.performDashboardSegue()
                    } else {
                        self.showLoginAlert(" Status Code: " + String(statusCode))
                    }
                }
        }
    }
    
    func showLoginAlert(message: String) {
        let alertController = UIAlertController(title: "Login Failed", message:
            "Your login has failed." + message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default,handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let theDestination = (segue.destinationViewController as! DashboardViewController)
        theDestination.authBase64 =  authBase64
        theDestination.serverAdress =  serverAdress
        theDestination.username =  username
        theDestination.saveLoginInfo = saveLoginSwitch.on
    }
    
    func performDashboardSegue() {
        performSegueWithIdentifier("showDashboardSegue", sender: self)
    }
}

extension String {
    var boolValue: Bool {
        return NSString(string: self).boolValue
    }}