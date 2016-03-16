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
    var UUID : String = ""
    
    //TMP - LOG ENABLE BOOL
    var experimentStarted = false
    var experimentRoundCounter = 1
    var experimentTouchCounter = 0
    var experimentStartTime : CFAbsoluteTime!
    var experimentPrios = [
        "Critical",
        "Normal",
        "Trivial",
        "Normal",
        "Critical",
        "Trivial",
        "Normal",
        "Critical",
        
        "Trivial",
        "Critical",
        "Normal",
        "Critical",
        "Normal",
        "Normal",
        "Critical",
        "Trivial",
        
        "Normal",
        "Trivial",
        "Critical",
        "Trivial",
        "Trivial",
        "Critical",
        "Trivial",
        "Normal"
    ]
    
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
        let rightAddBarButtonItem:UIBarButtonItem = UIBarButtonItem(title: "START", style: UIBarButtonItemStyle.Plain, target: self, action: "startExperiment:")
        self.navigationItem.setRightBarButtonItems([rightAddBarButtonItem], animated: true)
    }
    
    //TEMP!
    func showLoginAlert() {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Your UUID", message: "Enter a UUID", preferredStyle: .Alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.placeholder = "Insert UUID"
            textField.keyboardType = UIKeyboardType.NumberPad
        })
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let textField = alert.textFields![0] as UITextField
            self.UUID = textField.text!
            if (self.UUID != "") {
                self.handleExperimentStarted()
            } else {
                self.showLoginAlert()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Destructive, handler: { (UIAlertAction) -> Void in
        }))
        
        // 4. Present the alert.
        self.presentViewController(alert, animated: true, completion: nil)

    }
    
    func startExperiment(sender:UIButton) {
        showLoginAlert()
    }
    
    func handleExperimentStarted() {
        experimentStarted = true
        experimentStartTime = CFAbsoluteTimeGetCurrent()
        //1. Create the alert controller.
        let alert2 = UIAlertController(title: "Experiment Started", message: "Experiment has started.", preferredStyle: .Alert)
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert2.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
        }))
        
        // 4. Present the alert.
        self.presentViewController(alert2, animated: true, completion: nil)
        self.navigationItem.setRightBarButtonItem(nil, animated: false)
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
            loadIssuesWithNormalQuery()
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
    
    func loadIssuesWithNormalQuery() {
        loadIssues("jql=reporter=" + username + additionalJQLQuery.stringByReplacingOccurrencesOfString(" ", withString: "%20"))
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
                        self.loadIssuesWithNormalQuery()
                    }
                }
        }
    }
    
    func loadIssues(JQLQuery: String) {
        Alamofire.request(.GET, serverAdress + "/rest/api/latest/search?" + JQLQuery.stringByFoldingWithOptions(NSStringCompareOptions.DiacriticInsensitiveSearch, locale: NSLocale.currentLocale()) + maxResultsParameters)
            .responseJSON { response in
                if let JSON = response.result.value {
                    self.issuesArray.removeAll()
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
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Reported Issues"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! IssueTableViewCell
        let issue: PressureWeightViewController.issue
        let deepPressGestureRecognizer = DeepPressGestureRecognizer(target: self, action: "deepPressHandler:", threshold: 0.8)
        cell.addGestureRecognizer(deepPressGestureRecognizer)

        if (searchController.active && searchController.searchBar.text != "" && !JQL_MODE_ENABLED) {
            issue = filteredIssues[indexPath.row]
        } else {
            issue = issuesArray[indexPath.row]
        }
        
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
                        guard touchArray.count > 8 else {
                            forcedCell.backgroundColor = UIColor(red: (2.0 * recognizer.force), green: (2.0 * (1 - recognizer.force)), blue: 0, alpha: 1)
                            forcedCell.statusLabel.text = mapForceToTicketStatus(recognizer.force).uppercaseString
                            forcedCell.iconImageView.image = mapForceToTicketIcon(recognizer.force)
                            i++
                            return
                        }
                        forcedCell.backgroundColor = UIColor(red: (2.0 * touchArray[i-8]), green: (2.0 * (1 - touchArray[i-8])), blue: 0, alpha: 1)
                        forcedCell.statusLabel.text = mapForceToTicketStatus(touchArray[i-8]).uppercaseString
                        forcedCell.iconImageView.image = mapForceToTicketIcon(touchArray[i-8])
                        i++
                    }
                }
                
                if(recognizer.state == .Ended) {
                    let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
                    
                    if (activatedPressureWeight) {
                        let seconds = 0.25
                        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
                        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                        if (touchArray.count < 8) {
                            forcedCell.statusLabel.text = mapForceToTicketStatus(recognizer.force).uppercaseString
                            forcedCell.iconImageView.image = mapForceToTicketIcon(recognizer.force)
                        }
                        let status = mapForceToTicketStatus(touchArray[i-8])
                        forcedCell.statusLabel.text = status.uppercaseString
                        forcedCell.iconImageView.image = mapForceToTicketIcon(touchArray[i-8])

                        //TMP
                        if (experimentStarted) {
                            var matched = false
                            if (experimentPrios[experimentTouchCounter].uppercaseString == forcedCell.statusLabel.text) {
                                matched = true
                            }
                            QL2(timeRounding(elapsedTime), force: "originalPressureIssue", targetForce:"", userAge: "", userHanded: status, used3DTouch: "", uuid: UUID, numberOfExperimentsPassed: String(experimentRoundCounter), matchedTargetValue: String(matched), touchArray: forcedCell.titleLabel.text!)
                            experimentTouchCounter++
                            checkLastExperiment()
                        }
                        
                        sendNewIssueStatusToJira(status, issueKey: forcedCell.titleLabel.text!)
                        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                            forcedCell.backgroundColor = UIColor.whiteColor()
                            self.activatedPressureWeight = false
                            self.loadIssuesWithNormalQuery()
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
        case (force < 0.8):
            ret = prioritiesArray[prioritiesArray.count-3].title
            break
        case (force <= 1):
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
        case (force < 0.8):
            ret =  UIImage(named: "TAG Yellow")!
            break
        case (force <= 1):
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
    
    //TMP:
    func checkLastExperiment() {
        if (experimentTouchCounter == experimentPrios.count) {
            let elapsedTime = CFAbsoluteTimeGetCurrent() - experimentStartTime
            QL2("", force: "", targetForce:"ELAPSED TOTAL TIME:", userAge: self.timeRounding(elapsedTime), userHanded: "--", used3DTouch: "originalPressureIssue", uuid: self.UUID, numberOfExperimentsPassed:"" , matchedTargetValue: "", touchArray: "")
            handleExperimentStopped()
        }
    }
    
    func handleExperimentStopped() {
        //1. Create the alert controller.
        let alert2 = UIAlertController(title: "Round Finished", message: "Round has finished.", preferredStyle: .Alert)
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert2.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            if (self.experimentRoundCounter < 3) {
                self.presentNextRoundAlert()
            } else {
                self.presentFinish()
            }
        }))
        
        // 4. Present the alert.
        self.presentViewController(alert2, animated: true, completion: nil)
        self.navigationItem.setRightBarButtonItem(nil, animated: false)
    }
    
    func presentNextRoundAlert() {
        //1. Create the alert controller.
        let alert2 = UIAlertController(title: "Next Round", message: "Please go on.", preferredStyle: .Alert)
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert2.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            self.experimentTouchCounter = 0
            self.experimentStartTime = CFAbsoluteTimeGetCurrent()
            self.experimentRoundCounter++
        }))
        
        // 4. Present the alert.
        self.presentViewController(alert2, animated: true, completion: nil)
        self.navigationItem.setRightBarButtonItem(nil, animated: false)
    }
    
    func presentFinish() {
        experimentStarted = false
        //1. Create the alert controller.
        let alert2 = UIAlertController(title: "Experiment Finished", message: "Thank you!", preferredStyle: .Alert)
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert2.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
        }))
        
        // 4. Present the alert.
        self.presentViewController(alert2, animated: true, completion: nil)
        self.navigationItem.setRightBarButtonItem(nil, animated: false)
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