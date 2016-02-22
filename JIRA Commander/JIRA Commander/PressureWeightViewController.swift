//
//  PressureWeightViewController.swift
//  
//
//  Created by Tim Ordenewitz on 05.02.16.
//
//

import UIKit
import Alamofire

class PressureWeightViewController: UITableViewController{

    let cellIdentifier = "issueCell"
    var authBase64 :String = ""
    var serverAdress :String = ""
    var username :String = ""
    var startTime: CFAbsoluteTime!
    var i: Int = 0
    var activatedPressureWeight = false

    var authTempBase64 = "YWRtaW46YWRtaW4="
    let testJiraUrl = "http://46.101.221.171:8080"
    var additionalStatusQuery = "%20AND%20(status='to%20do'%20%20OR%20status='in%20progress')"

    
    struct issue {
        var title :String
        var description :String
        var issueStatus :String
    }
    
    struct priority {
        var title : String
        var id : String
    }
    
    var issuesArray = [issue]()
    var touchArray = [CGFloat]()
    var prioritiesArray = [priority]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        loadPriorities()
        loadIssues()
        
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        loadIssues()
        reloadIssueTable()
        refreshControl.endRefreshing()
    }
    
    func loadIssues() {
        issuesArray.removeAll()
        Alamofire.request(.GET, serverAdress + "/rest/api/latest/search?jql=reporter=" + username + additionalStatusQuery)
            .responseJSON { response in
                if let JSON = response.result.value {
                    if let issues = JSON["issues"] {
                        //All Issues Reported by User
                        for var index = 0; index < issues!.count; ++index{
                            if let fields = issues![index]["fields"] {
                                if let priority = fields!["priority"] {
                                    if let status = fields!["status"] {
                                        if let statusName = status!["name"] {
                                            if (!self.checkIfIssueIsClosed(statusName as! String)) {
                                                let myIssue = issue(title: issues![index]["key"] as! String, description: fields!["summary"] as! String, issueStatus: priority!["name"] as! String)
                                                self.issuesArray.append(myIssue)
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
    
    func loadPriorities() {
        prioritiesArray.removeAll()
        Alamofire.request(.GET, serverAdress + "/rest/api/2/priority")
            .responseJSON { response in
                if let JSON = response.result.value {
                    for var index = 0; index < JSON.count; ++index{
                        let myPriority = priority(title: JSON[index]["name"] as! String, id: JSON[index]["id"] as! String)
                        self.prioritiesArray.append(myPriority)
                    }
                }
        }
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
        return "Reported Issues"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! IssueTableViewCell
        let deepPressGestureRecognizer = DeepPressGestureRecognizer(target: self, action: "deepPressHandler:", threshold: 0.8)
        cell.addGestureRecognizer(deepPressGestureRecognizer)
        cell.titleLabel.text = issuesArray[indexPath.row].title
        cell.subtitleLabel.text = issuesArray[indexPath.row].description
        cell.statusLabel.text = issuesArray[indexPath.row].issueStatus.uppercaseString
        
        if (issuesArray[indexPath.row].issueStatus == prioritiesArray[prioritiesArray.count-5].title || issuesArray[indexPath.row].issueStatus == prioritiesArray[prioritiesArray.count-4].title) {
            cell.iconImageView.image = UIImage(named: "TAG Red")!
            return cell
        }
        if (issuesArray[indexPath.row].issueStatus == prioritiesArray[prioritiesArray.count-3].title) {
            cell.iconImageView.image = UIImage(named: "TAG Yellow")!
            return cell
        }
        else {
            cell.iconImageView.image = UIImage(named: "TAG Green")!
            return cell            
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func deepPressHandler(recognizer: DeepPressGestureRecognizer)
    {
        let forceLocation = recognizer.locationInView(self.tableView)
        if let forcedIndexPath = tableView.indexPathForRowAtPoint(forceLocation) {
            if let forcedCell  = self.tableView.cellForRowAtIndexPath(forcedIndexPath) as! IssueTableViewCell? {
                if(recognizer.state == .Began) {
                    startTime = CFAbsoluteTimeGetCurrent()
                }
                
                if(recognizer.state == .Changed) {
                    if (recognizer.force == 1.0) {
                        activatedPressureWeight = true
                    }
                    
                    if (activatedPressureWeight) {
                        touchArray.insert(recognizer.force, atIndex: i)
                        guard touchArray.count > 7 else {
                            forcedCell.backgroundColor = UIColor(red: (2.0 * recognizer.force), green: (2.0 * (1 - recognizer.force)), blue: 0, alpha: 1)
                            forcedCell.statusLabel.text = mapForceToTicketStatus(recognizer.force).uppercaseString
                            forcedCell.iconImageView.image = mapForceToTicketIcon(recognizer.force)
                            i++
                            return
                        }
                        forcedCell.backgroundColor = UIColor(red: (2.0 * touchArray[i-7]), green: (2.0 * (1 - touchArray[i-7])), blue: 0, alpha: 1)
                        forcedCell.statusLabel.text = mapForceToTicketStatus(touchArray[i-7]).uppercaseString
                        forcedCell.iconImageView.image = mapForceToTicketIcon(touchArray[i-7])
                        i++
                    }
                }
                
                if(recognizer.state == .Ended) {
                    if (activatedPressureWeight) {
                        let seconds = 0.25
                        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
                        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                        if (touchArray.count < 7) {
                            forcedCell.statusLabel.text = mapForceToTicketStatus(recognizer.force).uppercaseString
                            forcedCell.iconImageView.image = mapForceToTicketIcon(recognizer.force)
                        }
                        let status = mapForceToTicketStatus(touchArray[i-7])
                        forcedCell.statusLabel.text = status.uppercaseString
                        forcedCell.iconImageView.image = mapForceToTicketIcon(touchArray[i-7])
                        sendNewIssueStatusToJira(status, issueKey: forcedCell.titleLabel.text!)
                        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                            forcedCell.backgroundColor = UIColor.whiteColor()
                            self.activatedPressureWeight = false
                        })
                    }
                }
            }
        }
    }
    
    func mapForceToTicketStatus(force :CGFloat) -> String {
        var ret :String
        switch true {
        case (force < 0.2):
            ret = prioritiesArray[prioritiesArray.count-1].title
            break
        case (force < 0.3):
            ret = prioritiesArray[prioritiesArray.count-2].title
            break
        case (force < 0.7):
            ret = prioritiesArray[prioritiesArray.count-3].title
            break
        case (force < 0.9):
            ret = prioritiesArray[prioritiesArray.count-4].title
            break
        case (force <= 1.0):
            ret = prioritiesArray[prioritiesArray.count-5].title
            break
        default:
            ret = prioritiesArray[prioritiesArray.count-3].title
            break
        }
        return ret
    }
    
    func mapForceToTicketIcon(force :CGFloat) -> UIImage {
        var ret :UIImage
        switch true {
        case (force < 0.2):
            ret =  UIImage(named: "TAG Green")!
            break
        case (force < 0.3):
            ret =  UIImage(named: "TAG Green")!
            break
        case (force < 0.7):
            ret =  UIImage(named: "TAG Yellow")!
            break
        case (force < 0.9):
            ret =  UIImage(named: "TAG Red")!
            break
        case (force <= 1.0):
            ret =  UIImage(named: "TAG Red")!
            break
        default:
            ret =  UIImage(named: "TAG Yellow")!
            break
        }
        return ret
    }
    
    func sendNewIssueStatusToJira(status :String, issueKey :String) {
        let parameters = [
            "update": [
                "priority": [[
                    "set": [
                        "name": status
                    ]]
                ]
            ]
        ]
        
        Alamofire.request(.PUT, serverAdress + "/rest/api/2/issue/" + issueKey, parameters: parameters, encoding: .JSON)
            .responseJSON { response in
            }
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
