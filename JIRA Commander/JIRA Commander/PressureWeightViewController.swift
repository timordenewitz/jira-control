//
//  PressureWeightViewController.swift
//  
//
//  Created by Tim Ordenewitz on 05.02.16.
//
//

import UIKit
import Alamofire
import QorumLogs

class PressureWeightViewController: UITableViewController{

    let cellIdentifier = "issueCell"
    let epicCustomField = "customfield_10900"
    var authBase64 :String = ""
    var serverAdress :String = ""
    var username :String = ""
    var startTime: CFAbsoluteTime!
    var i: Int = 0
    var activatedPressureWeight = false
    let additionalJQLQuery = " AND (NOT status = 'Closed' AND NOT status = 'resolved' AND NOT status='done')"
    var authTempBase64 = "YWRtaW46YWRtaW4="
    let testJiraUrl = "http://46.101.221.171:8080"
    let maxResultsParameters = "&maxResults=500"
    let searchController = UISearchController(searchResultsController: nil)
    var JQL_MODE_ENABLED = false
    
    var issuesArray = [issue]()
    var filteredIssues = [issue]()

    var touchArray = [CGFloat]()
    var prioritiesArray = [priority]()
    
    struct issue {
        var title :String
        var description :String
        var issueStatus :String
    }
    
    struct priority {
        var title : String
        var id : String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
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
            navigationController?.navigationBar.backgroundColor = UIColor.whiteColor()

        }else {
            JQL_MODE_ENABLED = true
            searchController.searchBar.placeholder = "Search with JQL"
            navigationController!.navigationBar.tintColor = UIColor.jiraCommanderBlue()
            searchController.searchBar.barTintColor = UIColor.jiraCommanderBlue()
            navigationController?.navigationBar.backgroundColor = UIColor.jiraCommanderBlue()
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
        searchController.searchBar.keyboardType = UIKeyboardType.URL
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.placeholder = "Search in Issues"
    }
    
    func filterContentForSearchText(searchText: String) {
        filteredIssues = issuesArray.filter({( issue : PressureWeightViewController.issue) -> Bool in
            return issue.title.lowercaseString.containsString(searchText.lowercaseString)
        })
        tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        checkConnection()
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        refresh()
        refreshControl.endRefreshing()
    }
    
    func refresh() {
        if (JQL_MODE_ENABLED) {
            loadIssuesWithJQL()
        }else {
            loadIssues("jql=reporter=" + self.username + self.additionalJQLQuery.stringByReplacingOccurrencesOfString(" ", withString: "%20"))
        }
        reloadIssueTable()
    }
    
    func checkConnection() {
        if (serverAdress.isEmpty) {
            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("NavController") as! UINavigationController
            self.presentViewController(vc, animated: false, completion: nil)
        }
        Alamofire.request(.GET, serverAdress + "/rest/api/latest/myself")
            .responseJSON { response in
                if let statusCode = response.response?.statusCode {
                    if (statusCode == 200) {
                        self.loadPriorities()
                        self.loadIssues("jql=reporter=" + self.username + self.additionalJQLQuery.stringByReplacingOccurrencesOfString(" ", withString: "%20"))
                    }
                }
        }
    }
    
    func loadIssues(JQLQuery: String) {
        issuesArray.removeAll()
        Alamofire.request(.GET, serverAdress + "/rest/api/latest/search?" + JQLQuery.stringByFoldingWithOptions(NSStringCompareOptions.DiacriticInsensitiveSearch, locale: NSLocale.currentLocale()) + maxResultsParameters)
            .responseJSON { response in
                if let JSON = response.result.value {
                    if let issues = JSON["issues"] {
                        //All Issues Reported by User
                        if (response.response?.statusCode == 200) {
                            for var index = 0; index < issues!.count; ++index{
                                //Get All Fields
                                if let fields = issues![index]["fields"] {
                                    //Ger The Priority
                                    if let priority = fields!["priority"] {
                                        //Get The Epic Custom Field
                                        if let issueType = fields!["issuetype"] {
                                            //Get the Status
                                            if let status = fields!["status"] {
                                                if let statusName = status!["name"] {
                                                    if let issueTypeName = issueType!["name"] {
                                                        if (!self.checkIfIssueIsClosed(statusName as! String) && issueTypeName as! String != "Epic") {
                                                            let myIssue = issue(title: issues![index]["key"] as! String, description: fields!["summary"] as! String, issueStatus: priority!["name"] as! String)
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
        if (searchController.active && searchController.searchBar.text != "" && !JQL_MODE_ENABLED) {
            return filteredIssues.count
        }
        return self.issuesArray.count;
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let issue: PressureWeightViewController.issue
        if (searchController.active && searchController.searchBar.text != "" && !JQL_MODE_ENABLED) {
            issue = filteredIssues[indexPath.row]
        } else {
            issue = issuesArray[indexPath.row]
        }
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! IssueTableViewCell
        showAlertWasTapped(tableView, issue: issue, cell : cell)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Reported Issues"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! IssueTableViewCell
//        let deepPressGestureRecognizer = DeepPressGestureRecognizer(target: self, action: "deepPressHandler:", threshold: 0.8)
        let issue: PressureWeightViewController.issue

        if (searchController.active && searchController.searchBar.text != "" && !JQL_MODE_ENABLED) {
            issue = filteredIssues[indexPath.row]
        } else {
            issue = issuesArray[indexPath.row]
        }
        
//        cell.addGestureRecognizer(deepPressGestureRecognizer)
        cell.titleLabel.text = issue.title
        cell.subtitleLabel.text = issue.description
        cell.statusLabel.text = issue.issueStatus.uppercaseString
        
        
        if (issue.issueStatus == prioritiesArray[prioritiesArray.count-6].title) {
            cell.iconImageView.image = UIImage(named: "blocker")!
            return cell
        }
        if (issue.issueStatus == prioritiesArray[prioritiesArray.count-5].title || issue.issueStatus == prioritiesArray[prioritiesArray.count-4].title) {
            cell.iconImageView.image = UIImage(named: "TAG Red")!
            return cell
        }
        if (issue.issueStatus == prioritiesArray[prioritiesArray.count-3].title) {
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
    
    func deepPressHandler(recognizer: DeepPressGestureRecognizer) {
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
                    let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
                    QL2(timeRounding(elapsedTime), force: "originalPressureIssue", targetForce:"", userAge: "", userHanded: "", used3DTouch: "", uuid: "", numberOfExperimentsPassed: "", matchedTargetValue: "", touchArray: "")
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
    
    func timeRounding(time : Double) -> String {
        let numberOfPlaces = 2.0
        let multiplier = pow(10.0, numberOfPlaces)
        let rounded = round(time * multiplier) / multiplier
        return String(rounded)
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
        case (force < 0.6):
            ret = prioritiesArray[prioritiesArray.count-3].title
            break
        case (force < 0.8):
            ret = prioritiesArray[prioritiesArray.count-4].title
            break
        case (force < 0.95):
            ret = prioritiesArray[prioritiesArray.count-5].title
            break
        case (force <= 1.0):
            ret = prioritiesArray[prioritiesArray.count-6].title
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
        case (force < 0.6):
            ret =  UIImage(named: "TAG Yellow")!
            break
        case (force < 0.8):
            ret =  UIImage(named: "TAG Red")!
            break
        case (force < 0.95):
            ret =  UIImage(named: "TAG Red")!
            break
        case (force <= 1.0):
            ret =  UIImage(named: "blocker")!
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
    
    func showAlertWasTapped(table : UITableView, issue: PressureWeightViewController.issue, cell: IssueTableViewCell) {
        
        let alertController = UIAlertController(title: "Priority", message: "Set the priority for the issue.", preferredStyle: UIAlertControllerStyle.ActionSheet)
        for priority in prioritiesArray {
            let tmpAction = UIAlertAction(title: priority.title, style: UIAlertActionStyle.Default, handler: {(alert :UIAlertAction) in
                self.sendNewIssueStatusToJira(priority.title, issueKey: issue.title)
                cell.statusLabel.text = priority.title.uppercaseString
                if (priority.title == self.prioritiesArray[self.prioritiesArray.count-6].title) {
                    cell.iconImageView.image = UIImage(named: "blocker")!
                }
                if (priority.title == self.prioritiesArray[self.prioritiesArray.count-5].title || priority.title == self.prioritiesArray[self.prioritiesArray.count-4].title) {
                    cell.iconImageView.image = UIImage(named: "TAG Red")!
                }
                if (priority.title == self.prioritiesArray[self.prioritiesArray.count-3].title) {
                    cell.iconImageView.image = UIImage(named: "TAG Yellow")!
                }
                if (priority.title == self.prioritiesArray[self.prioritiesArray.count-2].title || priority.title == self.prioritiesArray[self.prioritiesArray.count-1].title) {
                    cell.iconImageView.image = UIImage(named: "TAG Green")!
                }
            })
            alertController.addAction(tmpAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: {(alert :UIAlertAction) in
        })
        alertController.addAction(cancelAction)

        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = table.frame
        
        presentViewController(alertController, animated: true, completion: nil)
        
    }
}
extension PressureWeightViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if (JQL_MODE_ENABLED) {
            loadIssuesWithJQL()
        }else {
            filterContentForSearchText(searchBar.text!)
        }
    }
}

extension PressureWeightViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if (JQL_MODE_ENABLED) {
            loadIssuesWithJQL()
        }else {
            filterContentForSearchText(searchController.searchBar.text!)
        }
    }
}