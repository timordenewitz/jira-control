//
//  StressTicketViewController.swift
//  JIRA Commander
//
//  Created by Tim Ordenewitz on 08.02.16.
//  Copyright © 2016 Tim Ordenewitz. All rights reserved.
//

import UIKit
import Alamofire

class StressTicketViewController: UITableViewController {
    
    let authBase64 :String = ""
    let serverAdress :String = ""
    var username :String = ""
    let cellIdentifier = "stressTicketCell"
    
    struct issue {
        var title :String
        var description :String
        var assignee :String?
        var profilePictureURL : String?
    }
    
    enum status: String{
        case Highest
        case High
        case Medium
        case Low
        case Lowest
    }
    
    var issuesArray = [issue]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        loadIssues()
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        loadIssues()
        reloadIssueTable()
        refreshControl.endRefreshing()
    }
    
    func loadIssues() {
        issuesArray.removeAll()
        Alamofire.request(.GET, "http://46.101.221.171:8080/rest/api/latest/search?jql=creator=" + "admin", headers: ["Authorization" : "Basic " + "YWRtaW46YWRtaW4="])
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // URL response
                print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    if let issues = JSON["issues"] {
                        //All Issues Reported by User
                        for var index = 0; index < issues!.count; ++index{
                            if let fields = issues![index]["fields"] {
                                if let assignee = fields!["assignee"] {
                                    if let avatarURLs = assignee!["avatarUrls"] {
                                        let myIssue = issue(title: issues![index]["key"] as! String, description: fields!["summary"] as! String, assignee: assignee!["name"] as! String?, profilePictureURL:avatarURLs!["48x48"] as! String?)
                                        self.issuesArray.append(myIssue)
                                        print(myIssue)
                                    }
                                    else {
                                        let myIssue = issue(title: issues![index]["key"] as! String, description: fields!["summary"] as! String, assignee: nil, profilePictureURL:nil)
                                        self.issuesArray.append(myIssue)
                                        print(myIssue)
                                    }
                                }
                            }
                        }
                        self.reloadIssueTable()
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
        return "Stress Issues"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! StressTicketTableViewCell
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
        
        return cell
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