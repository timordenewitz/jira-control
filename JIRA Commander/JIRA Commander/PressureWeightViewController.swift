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

    var items: [String] = ["We", "Heart", "Swift"]
    let cellIdentifier = "issueCell"
    var authBase64 :String = ""
    var serverAdress :String = ""
    var username :String = ""
    
    enum status: String{
        case CRITICAL
        case TRIVIAL
        case NORMAL
    }
    
    struct issue {
        var title :String
        var desctiption :String
        var issueStatus :String
    }
    
    var issuesArray = [issue]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        loadIssues()
    }
    
    func loadIssues() {
        Alamofire.request(.GET, "http://46.101.221.171:8080/rest/api/latest/search?jql=reporter=" + "admin", headers: ["Authorization" : "Basic " + "YWRtaW46YWRtaW4="])
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // URL response
                print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    if let issues = JSON["issues"] {
                        //All Issues Reported by User
                        for var index = 0; index < issues!.count; ++index{
                            if let fields = issues![index]["fields"] {
                                if let priority = fields!["priority"] {
                                    let myIssue = issue(title: issues![index]["key"] as! String, desctiption: fields!["summary"] as! String, issueStatus: priority!["name"] as! String)
                                    self.issuesArray.append(myIssue)
                                    print(myIssue)
                                }
                            }
                        }
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.reloadData()
                        })
                    }
                }
        }
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
        cell.titleLabel.text = issuesArray[indexPath.row].title
        cell.subtitleLabel.text = issuesArray[indexPath.row].desctiption
        cell.statusLabel.text = issuesArray[indexPath.row].issueStatus.uppercaseString
        cell.iconImageView.image = UIImage(named: "TAG Green")!
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
