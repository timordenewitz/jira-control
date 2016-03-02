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
import SWTableViewCell

class StressTicketViewController: UITableViewController, SWTableViewCellDelegate{
    
    var authBase64 :String = ""
    var serverAdress :String = ""
    var username :String = ""
    let cellIdentifier = "stressTicketCell"
    let additionalJQLQuery = " AND (NOT status = 'Closed' AND NOT status = 'resolved' AND NOT status='done')"
    let searchController = UISearchController(searchResultsController: nil)
    let STRESSED_LABEL_FOR_JIRA = "Stressed"
    var JQL_MODE_ENABLED = false
    
    struct issue {
        var title :String
        var description :String
        var assignee :String?
        var profilePictureURL : String?
        var stressed :Bool
    }
    
    var issuesArray = [issue]()
    var filteredIssues = [issue]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        checkConnection()
        setupSearchBar()
        let rightAddBarButtonItem:UIBarButtonItem = UIBarButtonItem(title: "JQL", style: UIBarButtonItemStyle.Plain, target: self, action: "performJQL:")
        self.navigationItem.setRightBarButtonItems([rightAddBarButtonItem], animated: true)
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.navigationBar.backgroundColor = UIColor.whiteColor()
        navigationController!.navigationBar.tintColor = UIColor.blackColor()
        searchController.searchBar.barTintColor = UIColor.whiteColor()
    }
    
    func performJQL (sender:UIButton) {
        if (JQL_MODE_ENABLED) {
            JQL_MODE_ENABLED = false
            searchController.searchBar.placeholder = "Search in Issues"
            loadIssues("jql=reporter=" + username + additionalJQLQuery.stringByReplacingOccurrencesOfString(" ", withString: "%20"))
            navigationController!.navigationBar.tintColor = UIColor.blackColor()
            searchController.searchBar.barTintColor = UIColor.whiteColor()
        }else {
            JQL_MODE_ENABLED = true
            searchController.searchBar.placeholder = "Search with JQL"
            navigationController!.navigationBar.tintColor = UIColor.jiraCommanderBlue()
            searchController.searchBar.barTintColor = UIColor.jiraCommanderBlue()
        }
    }
    
    func loadIssuesWithJQL() {
        if(searchController.searchBar.text != ""){
            loadIssues("jql=" + (searchController.searchBar.text?.stringByReplacingOccurrencesOfString(" ", withString: "%20"))!)
            tableView.reloadData()
        }
    }
    
    func setupSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func filterContentForSearchText(searchText: String) {
        filteredIssues = issuesArray.filter({( issue : StressTicketViewController.issue) -> Bool in
            return issue.title.lowercaseString.containsString(searchText.lowercaseString)
        })
        tableView.reloadData()
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
                        self.loadIssues("jql=reporter=" + self.username + self.additionalJQLQuery.stringByReplacingOccurrencesOfString(" ", withString: "%20"))
                    }
                }
        }
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        if (JQL_MODE_ENABLED) {
            loadIssuesWithJQL()
        }else {
            loadIssues("jql=creator=" + self.username + self.additionalJQLQuery.stringByReplacingOccurrencesOfString(" ", withString: "%20"))
        }
        reloadIssueTable()
        refreshControl.endRefreshing()
    }
    
    func loadIssues(JQLQuery: String) {
        issuesArray.removeAll()
        Alamofire.request(.GET, serverAdress + "/rest/api/latest/search?" + JQLQuery)
            .responseJSON { response in
                if let JSON = response.result.value {
                    if let issues = JSON["issues"] {
                        //All Issues Reported by User
                        if (response.response?.statusCode == 200) {
                            print(response.response)
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
    }
    
    func checkIfIssueIsClosed(name : String) -> Bool {
        if (name == "Closed") {
            return true
        }
        return false
    }
    
    
    func checkIfIssueGotStressed(labels : AnyObject) -> Bool {
        for var i = 0; i < labels.count; ++i {
            if (labels[i] == STRESSED_LABEL_FOR_JIRA) {
                return true
            }
        }
        return false
    }
    
    func reloadIssueTable() {
        filterContentForSearchText(searchController.searchBar.text!)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (searchController.active && searchController.searchBar.text != "" && !JQL_MODE_ENABLED) {
            return filteredIssues.count
        }
        return self.issuesArray.count;
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Stress Issues"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! StressTicketTableViewCell
        let deepPressGestureRecognizer = DeepPressGestureRecognizer(target: self, action: "deepPressHandler:", threshold: 0.8)
        tableView.addGestureRecognizer(deepPressGestureRecognizer)
        let issue: StressTicketViewController.issue
        cell.profilePictureImageView.image = nil
        
        if (searchController.active && searchController.searchBar.text != "" && !JQL_MODE_ENABLED) {
            issue = filteredIssues[indexPath.row]
        } else {
            issue = issuesArray[indexPath.row]
        }
        
        cell.delegate = self;
        cell.issueTitleLabel.text = issue.title
        cell.issuesSummaryLabel.text = issue.description
        cell.assigneeLabel.text = issue.assignee?.uppercaseString
        if let url = issue.profilePictureURL {
            cell.profilePictureImageView.imageFromUrl(url)
            let image = cell.profilePictureImageView
            image.layer.borderWidth = 0
            image.layer.masksToBounds = false
            image.layer.borderColor = UIColor.whiteColor().CGColor
            image.layer.cornerRadius = image.frame.height/2
            image.clipsToBounds = true
        }
        if (issue.stressed) {
            cell.stressedImageView.hidden = false
            cell.stressedImageView.image = UIImage(named: "Stressed-Badge")
            cell.stressed = true
            cell.rightUtilityButtons = self.getRightUtilityButtonsToCell() as [AnyObject];
        } else {
            cell.stressedImageView.hidden = true
            cell.stressed = false
            cell.backgroundColor = UIColor.whiteColor()
            cell.rightUtilityButtons = []
        }
        return cell
    }
    
    func deepPressHandler(recognizer: DeepPressGestureRecognizer) {
        let forceLocation = recognizer.locationInView(self.tableView)
        if let forcedIndexPath = tableView.indexPathForRowAtPoint(forceLocation) {
            if let forcedCell  = self.tableView.cellForRowAtIndexPath(forcedIndexPath) as! StressTicketTableViewCell? {
                if(recognizer.state == .Changed) {
                    if (recognizer.force == 1.0) {
                        if (!forcedCell.stressed) {
                            forcedCell.stressed = true
                            forcedCell.backgroundColor = UIColor.redColor()
                            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                            sendNewStressedStatusToJira(STRESSED_LABEL_FOR_JIRA, issueKey: forcedCell.issueTitleLabel.text!)
                        }
                    }
                }
                
                if(recognizer.state == .Ended) {
                    filterContentForSearchText(searchController.searchBar.text!)
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
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func getRightUtilityButtonsToCell()-> NSMutableArray{
        let utilityButtons: NSMutableArray = NSMutableArray()
        
        utilityButtons.sw_addUtilityButtonWithColor(UIColor.jiraCommanderRed(), title: NSLocalizedString("Remove", comment: ""))
        return utilityButtons
    }
    
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
        if index == 0 {
            handleDeStress(cell as! StressTicketTableViewCell)
        }
        cell.hideUtilityButtonsAnimated(true);
    }
    
    func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell!) -> Bool {
        return true
    }
    
    func handleDeStress(cell : StressTicketTableViewCell) {
        sendRemoveStressedStatusToJira(STRESSED_LABEL_FOR_JIRA, issueKey: cell.issueTitleLabel.text!)
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
        sendIssueRequest(issueKey, parameters: parameters)
    }
    
    func sendRemoveStressedStatusToJira(status :String, issueKey: String) {
        let parameters = [
            "update": [
                "labels": [[
                    "remove": status
                    ]
                ]
            ]
        ]
        sendIssueRequest(issueKey, parameters: parameters)
    }
    
    func sendIssueRequest(issueKey : String, parameters : [String : Dictionary<String, Array<Dictionary<String, String>>>]) {
        Alamofire.request(.PUT, serverAdress + "/rest/api/2/issue/" + issueKey, parameters: parameters, encoding: .JSON).responseJSON {
            response in
            if (self.JQL_MODE_ENABLED) {
                self.loadIssuesWithJQL()
            }else {
                self.loadIssues("jql=creator=" + self.username + self.additionalJQLQuery.stringByReplacingOccurrencesOfString(" ", withString: "%20"))
            }
        }
    }
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


extension StressTicketViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if (JQL_MODE_ENABLED) {
            loadIssuesWithJQL()
        }else {
            filterContentForSearchText(searchBar.text!)
        }
    }
}

extension StressTicketViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if (JQL_MODE_ENABLED) {
            loadIssuesWithJQL()
        }else {
            filterContentForSearchText(searchController.searchBar.text!)
        }
    }
}

extension UIColor {
    static func jiraCommanderRed() -> UIColor {
        return UIColor(red: 208/255, green: 69/255, blue: 55/255, alpha: 1)
    }
}