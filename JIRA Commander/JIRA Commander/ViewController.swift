//
//  ViewController.swift
//  JIRA Commander
//
//  Created by Tim Ordenewitz on 05.02.16.
//  Copyright © 2016 Tim Ordenewitz. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var EmailTextField: UITextField!
    @IBOutlet var PWTextField: UITextField!
    @IBOutlet var ServerAdressTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        EmailTextField.attributedPlaceholder = NSAttributedString(string:"EMAIL",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        EmailTextField.delegate = self
        
        PWTextField.attributedPlaceholder = NSAttributedString(string:"PASSWORD",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        PWTextField.delegate = self

        ServerAdressTextField.attributedPlaceholder = NSAttributedString(string:"SERVER ADRESS",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        ServerAdressTextField.delegate = self

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
}

