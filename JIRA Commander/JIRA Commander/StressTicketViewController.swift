//
//  StressTicketViewController.swift
//  JIRA Commander
//
//  Created by Tim Ordenewitz on 08.02.16.
//  Copyright © 2016 Tim Ordenewitz. All rights reserved.
//

import UIKit
import Alamofire
import AudioToolbox

class StressTicketViewController: UITableViewController {
    
    var authBase64 :String = ""
    var serverAdress :String = ""
    var username :String = ""
    let cellIdentifier = "stressTicketCell"
    var additionalStatusQuery = "%20AND%20(status='to%20do'%20%20OR%20status='in%20progress')"
    
    struct issue {
        var title :String
        var description :String
        var assignee :String?
        var profilePictureURL : String?
        var stressed :Bool
    }
    
    var issuesArray = [issue]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        checkConnection()
    }
    
    func checkConnection(){
        if (serverAdress.isEmpty) {
            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("NavController") as! UINavigationController
            self.presentViewController(vc, animated: false, completion: nil)
        }
        Alamofire.request(.GET, serverAdress + "/rest/api/latest/myself")
            .responseJSON { response in
                if let statusCode = response.response?.statusCode {
                    if (statusCode == 200) {
                        print("200")
                        self.loadIssues()
                    }
                }
        }
    }

    
    func handleRefresh(refreshControl: UIRefreshControl) {
        loadIssues()
        reloadIssueTable()
        refreshControl.endRefreshing()
    }
    
    func loadIssues() {
        issuesArray.removeAll()
        Alamofire.request(.GET, serverAdress + "/rest/api/latest/search?jql=creator=" + username + additionalStatusQuery)
            .responseJSON { response in
                if let JSON = response.result.value {
                    if let issues = JSON["issues"] {
                        //All Issues Reported by User
                        for var index = 0; index < issues!.count; ++index{
                            if let fields = issues![index]["fields"] {
                                if let assignee = fields!["assignee"] {
                                    if let labels = fields!["labels"] {
                                        if let status = fields!["status"] {
                                            if let statusName = status!["name"] {
                                                if (!self.checkIfIssueIsClosed(statusName as! String)) {
                                                    if let avatarURLs = assignee!["avatarUrls"] {
                                                        let myIssue = issue(title: issues![index]["key"] as! String, description: fields!["summary"] as! String, assignee: assignee!["name"] as! String?, profilePictureURL:avatarURLs!["48x48"] as! String?, stressed: self.checkIfIssueGotStressed(labels!))
                                                        self.issuesArray.append(myIssue)
                                                    }
                                                    else {
                                                        let myIssue = issue(title: issues![index]["key"] as! String, description: fields!["summary"] as! String, assignee: nil, profilePictureURL:nil, stressed: self.checkIfIssueGotStressed(labels!))
                                                        self.issuesArray.append(myIssue)
                                                    }
                                                }

                                            }
                                        }
                                    }
                                }
                            }
                        }
                        self.reloadIssueTable()
                    }
                }
        }
    }
    
    func checkIfIssueIsClosed(name : String) -> Bool {
        if (name == "Closed") {
            return true
        }
        return false
    }
    
    
    func checkIfIssueGotStressed(labels : AnyObject) -> Bool {
        for var i = 0; i < labels.count; ++i {
            if (labels[i] == "Stressed") {
                return true
            }
        }
        return false
    }
    
    func reloadIssueTable() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.issuesArray.count;
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Stress Issues"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! StressTicketTableViewCell
        let deepPressGestureRecognizer = DeepPressGestureRecognizer(target: self, action: "deepPressHandler:", threshold: 0.8)
        tableView.addGestureRecognizer(deepPressGestureRecognizer)
        cell.issueTitleLabel.text = issuesArray[indexPath.row].title
        cell.issuesSummaryLabel.text = issuesArray[indexPath.row].description
        cell.assigneeLabel.text = issuesArray[indexPath.row].assignee?.uppercaseString
        if let url = issuesArray[indexPath.row].profilePictureURL {
            cell.profilePictureImageView.imageFromUrl(url)
            let image = cell.profilePictureImageView
            image.layer.borderWidth = 0
            image.layer.masksToBounds = false
            image.layer.borderColor = UIColor.whiteColor().CGColor
            image.layer.cornerRadius = image.frame.height/2
            image.clipsToBounds = true
        }
        if (issuesArray[indexPath.row].stressed) {
            cell.stressedImageView.hidden = false
            cell.stressedImageView.image = UIImage(named: "Stressed-Badge")
            cell.stressed = true
        } else {
            cell.stressedImageView.hidden = true
            cell.stressed = false
        }
        return cell
    }
    
    func deepPressHandler(recognizer: DeepPressGestureRecognizer)
    {
        let forceLocation = recognizer.locationInView(self.tableView)
        if let forcedIndexPath = tableView.indexPathForRowAtPoint(forceLocation) {
            if let forcedCell  = self.tableView.cellForRowAtIndexPath(forcedIndexPath) as! StressTicketTableViewCell? {
                if(recognizer.state == .Changed) {
                    if (recognizer.force == 1.0) {
                        if (!forcedCell.stressed) {
                            forcedCell.backgroundColor = UIColor.redColor()
                            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                            sendNewStressedStatusToJira("Stressed", issueKey: forcedCell.issueTitleLabel.text!)
                            loadIssues()
                        }
                    }
                }
                
                if(recognizer.state == .Ended) {
                        let seconds = 0.25
                        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
                        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                            forcedCell.backgroundColor = UIColor.whiteColor()
                        })
                }
            }
        }
    }
    
    func sendNewStressedStatusToJira(status :String, issueKey: String) {
        let parameters = [
            "update": [
                "labels": [[
                    "add": status
                    ]
                ]
            ]
        ]

        Alamofire.request(.PUT, serverAdress + "/rest/api/2/issue/" + issueKey, parameters: parameters, encoding: .JSON)
            .responseJSON { response in
                print(response.request)
                print(response.response)
                print(response.result)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UIImageView {
    public func imageFromUrl(urlString: String) {
        if let url = NSURL(string: urlString) {
            let request = NSURLRequest(URL: url)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                if let imageData = data as NSData? {
                    self.image = UIImage(data: imageData)
                }
            }
        }
    }
}