//
//  DiagramViewController.swift
//  JIRA Commander
//
//  Created by Tim Ordenewitz on 08.02.16.
//  Copyright © 2016 Tim Ordenewitz. All rights reserved.
//

import UIKit
import Charts
import Alamofire
import Foundation

class DiagramViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var authBase64 :String = ""
    var serverAdress :String = ""
    var projects = Set<Project>()
    var sprints = Set<Sprint>()

    var currentProject : String = ""
    
    let storyPointKey = "customfield_10002"
    let sprintInfoField = "customfield_10005"
    var issuesArray = [Issue]()
    var resolvedIssues = [ResolvedIssue]()
    
    let searchQuery="(sprint%20in%20openSprints%20())"
    let maxResultsParameters = "&maxResults=5000"
    
    var projectTitles :[String] = []
    
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var pickerViewOutlet: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProjects()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setChart(dataPoints: [String], values: [Double]) {
        lineChartView.noDataText = "You need to provide data for the chart."
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: "Story Points Remaining")
        let lineChartData = LineChartData(xVals: dataPoints, dataSet: lineChartDataSet)
        lineChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        lineChartView.data = lineChartData
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func loadProjects() {
        Alamofire.request(.GET, serverAdress + "/rest/api/latest/search?jql=" + searchQuery + maxResultsParameters)
            .responseJSON { response in
                if let JSON = response.result.value {
                    if let issues = JSON["issues"] {
                        //All Issues Reported by User
                        for var index = 0; index < issues!.count; ++index {
                            var tmpProject : Project
                            if let fields = issues![index]["fields"] {
                                if let projectArray = fields!["project"] {
                                    tmpProject = Project(title: projectArray!["name"] as! String, key: projectArray!["key"] as! String)
                                    self.projects.insert(tmpProject)
                                
                                    if let sprintInfo = fields![self.sprintInfoField] {
                                        for var index = 0; index < sprintInfo!.count; ++index {
                                            var myTempStrArray = sprintInfo![index].componentsSeparatedByString(",")
                                            let sprintName = myTempStrArray[3].componentsSeparatedByString("=")[1]
                                            let sprintStartDate = self.getDateFromObject(myTempStrArray[4].componentsSeparatedByString("=")[1])
                                            let sprintEndDate = self.getDateFromObject(myTempStrArray[5].componentsSeparatedByString("=")[1])
                                            self.sprints.insert(Sprint(name: sprintName, startDate: sprintStartDate, endDate: sprintEndDate, maxStoryPoints: 0, project: tmpProject))
                                        }
                                    }
                                }
                            }
                        }
                        for var index = 0; index < issues!.count; ++index{
                            if let fields = issues![index]["fields"] {
                                if let projectArray = fields!["project"] {
                                    if let storyPointsJSON = fields![self.storyPointKey] {
                                        if (!(storyPointsJSON is NSNull)) {
                                            if let resolutionDateJSON = fields!["resolutiondate"] {
                                                if (!(resolutionDateJSON is NSNull)) {
                                                    let date = self.getDateFromObject(resolutionDateJSON! as! String)
                                                    if let sprintInfo = fields![self.sprintInfoField] {
                                                        for var index = 0; index < sprintInfo!.count; ++index {
                                                            var myTempStrArray = sprintInfo![index].componentsSeparatedByString(",")
                                                            let sprintName = myTempStrArray[3].componentsSeparatedByString("=")[1]
                                                            for sprintObject in self.sprints {
                                                                if (sprintObject.name == sprintName) {
                                                                    self.resolvedIssues.append(ResolvedIssue(date: date, numberOfStorypoints: storyPointsJSON!.integerValue!, project: self.getProjectByName(projectArray!["name"] as! String)!, sprintName: sprintName))
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                }
                            }
                        }
                        self.computeMaxStorypointForSprint()
                        self.createProjectsArray()
                        self.pickerViewOutlet.reloadAllComponents()
                        self.buildDiagramDataValues(self.resolvedIssues, project: (self.projects.first?.title)!)
                    }
                }
        }
    }
    
    func computeMaxStorypointForSprint() {
        for issueObject in resolvedIssues {
            for sprintObject in sprints {
                if (sprintObject.name == issueObject.sprintName) {
                    var tmpSprint = sprintObject
                    sprints.remove(sprintObject)
                    tmpSprint.maxStoryPoints = tmpSprint.maxStoryPoints! + issueObject.numberOfStorypoints
                    sprints.insert(tmpSprint)
                }
            }
        }
    }
    
    
//
//    func getIssueKeysPerProject() {
//        Alamofire.request(.GET, serverAdress + "/rest/api/latest/search?jql=" + searchQuery + maxResultsParameters)
//            .responseJSON { response in
//                if let JSON = response.result.value {
//                    if let issues = JSON["issues"] {
//                        //All Issues Reported by User
//                        for var index = 0; index < issues!.count; ++index{
//                            if let fields = issues![index]["fields"] {
//                                if let projectArray = fields!["project"] {
//                                    for project in self.projects {
//                                        if(project.title == (projectArray!["name"] as! String)) {
//                                            var tmpProject = project
//                                            self.projects.remove(project)
//                                            tmpProject.issueKeys.append(issues![index]["key"] as! String)
//                                            self.projects.insert(tmpProject)
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                    self.getSprintsPerProject()
//                }
//        }
//    }

//    func getSprintsPerProject() {
//        for project in projects {
//            for key in project.issueKeys {
//                Alamofire.request(.GET, serverAdress + "/rest/agile/1.0/issue/" + key)
//                    .responseJSON { response in
//                        if let JSON = response.result.value {
//                            if let fields = JSON["fields"] {
//                                //All Issues Reported by User
//                                if let sprint = fields!["sprint"] {
//                                    let tmpSprint = Sprint(id: sprint!["id"]!!.stringValue, startDate: self.getDateFromObject(sprint!["startDate"] as! String), endDate: self.getDateFromObject(sprint!["endDate"] as! String), issues:[], issueKeys : [])
//                                    self.sprints.insert(tmpSprint)
//                                    
//                                }
//                            }
//                        }
//                }
//            }
//        }
//        self.getIssuesForSprint()
//    }
//    
//    func getIssuesForSprint() {
//        
//        
//        for project in projects {
//            for key in project.issueKeys {
//                Alamofire.request(.GET, serverAdress + "/rest/agile/1.0/issue/" + key)
//                    .responseJSON { response in
//                        if let JSON = response.result.value {
//                            if let fields = JSON["fields"] {
//                                //All Issues Reported by User
//                                if let sprint = fields!["sprint"] {
//                                    for sprintObject in self.sprints {
//                                        if(sprintObject.id == (sprint!["id"]!!.stringValue)) {
//                                            var tmpSprint = sprintObject
//                                            self.sprints.remove(sprintObject)
//                                            tmpSprint.issueKeys.append(key)
//                                            self.sprints.insert(tmpSprint)
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                }
//            }
//        }
//    }
    
    

    
//    func getStorypointsPerProject() {
//        Alamofire.request(.GET, serverAdress + "/rest/api/latest/search?jql=" + searchQuery + maxResultsParameters)
//            .responseJSON { response in
//                if let JSON = response.result.value {
//                    if let issues = JSON["issues"] {
//                        //All Issues Reported by User
//                        for var index = 0; index < issues!.count; ++index{
//                            if let fields = issues![index]["fields"] {
//                                if let projectArray = fields!["project"] {
//                                    if let storyPointsJSON = fields![self.storyPointKey] {
//                                        if (!(storyPointsJSON is NSNull)) {
//                                            for project in self.projects {
//                                                if(project.title == (projectArray!["name"] as! String)) {
//                                                    var tmpProject = project
//                                                    self.projects.remove(project)
//                                                    tmpProject.maxStoryPoints = (tmpProject.maxStoryPoints! + (storyPointsJSON?.integerValue!)!)
//                                                    self.projects.insert(tmpProject)
//                                                }
//                                            }
//                                        }
//                                    }
//                                    
//                                }
//                            }
//                        }
//                    }
//                   self.loadIssues()
//                }
//        }
//    }
    
    
    


    
//    func loadIssues() {
//        Alamofire.request(.GET, serverAdress + "/rest/api/latest/search?jql=" + searchQuery + maxResultsParameters)
//            .responseJSON { response in
//                if let JSON = response.result.value {
//                    if let issues = JSON["issues"] {
//                        //All Issues Reported by User
//                        for var index = 0; index < issues!.count; ++index{
//                            if let fields = issues![index]["fields"] {
//                                if let projectArray = fields!["project"] {
//                                    if let storyPointsJSON = fields![self.storyPointKey] {
//                                        if (!(storyPointsJSON is NSNull)) {
//                                            if let resolutionDateJSON = fields!["resolutiondate"] {
//                                                if (!(resolutionDateJSON is NSNull)) {
//                                                    let date = self.getDateFromObject(resolutionDateJSON! as! String)
//                                                    self.resolvedIssues.append(ResolvedIssue(date: date, numberOfStorypoints: storyPointsJSON!.integerValue!, project: self.getProjectByName(projectArray!["name"] as! String)!) )
//                                                }
//                                            }
//                                        }
//                                    }
//
//                                }
//                            }
//                        }
//                    }
//                    self.pickerViewOutlet.reloadAllComponents()
//                    self.buildDiagramDataValues(self.resolvedIssues, project: (self.projects.first?.title)!)
//            }
//        }
//    }
    
    func getDateFromObject(dateObject : String) -> NSDate {
        var myStringArr = dateObject.componentsSeparatedByString("T")
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone =  NSTimeZone(name: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.dateFromString(myStringArr[0])!
    }
    
//    func getSprintForIssue(key : String) -> Sprint {
//        Alamofire.request(.GET, serverAdress + "rest/agile/1.0/issue/" + key)
//            .responseJSON { response in
//                if let JSON = response.result.value {
//                    if let fields = JSON["fields"] {
//                        if let sprint = fields!["sprint"] {
//                            Sprint(id: sprint!["id"] as! String, startDate: self.getDateFromObject(sprint!["startDate"]) , endDate:  self.getDateFromObject(sprint!["startDate"]), issues: [])
//                        }
//                    }
//                }
//        }
//    }
    
    func createProjectsArray() {
        for project in projects {
            projectTitles.append(project.title)
        }
    }
    
    func getProjectByName(name :String) -> Project? {
        for project in self.projects {
            if(project.title == name) {
                return project
            }
        }
        return nil
    }
    
    func buildDiagramDataValues(resolvedIssues : [ResolvedIssue], project : String) {
        let filteredIssues = filterIssuesByProject(resolvedIssues, project: project)
        let orderedResolvedIssues = orderByDate(filteredIssues)
        let xAxisDataSet = buildXAxisDataSet(orderedResolvedIssues)
        let valueDataSet = buildValueDataSet(orderedResolvedIssues)
        setChart(xAxisDataSet, values: valueDataSet)
        
    }
    
    func buildXAxisDataSet(orderedResolvedIssues : [ResolvedIssue]) -> [String] {
        var tmpArray :[String] = []
        tmpArray.append("Start")
        for var index = 0; index < orderedResolvedIssues.count; ++index {
            var tmpStr = String(orderedResolvedIssues[index].date).componentsSeparatedByString(" ")
            tmpArray.append(tmpStr[0])
        }
        tmpArray = uniq(tmpArray)
        return tmpArray
    }

    func buildValueDataSet(orderedResolvedIssues : [ResolvedIssue]) -> [Double] {
        var tmpDoubleArray : [Double] = []
        var tmpStringArray : [String] = []
        var tmpMaxStoryPoints = 0.0
        
        guard orderedResolvedIssues.count != 0 else {
            return [0.0]
        }
        
        for var index = 0; index < orderedResolvedIssues.count; ++index {
            tmpStringArray.append(String(orderedResolvedIssues[index].date))
        }
        tmpStringArray = uniq(tmpStringArray)
        
        for sprintObject in sprints {
            if (sprintObject.name == orderedResolvedIssues[0].sprintName) {
                tmpMaxStoryPoints = Double(sprintObject.maxStoryPoints!)
                tmpDoubleArray.append(tmpMaxStoryPoints)
            }
        }
        
        
        for var index = 0; index < tmpStringArray.count; ++index {
            var tmpInt = 0
            for var index2 = 0; index2 < orderedResolvedIssues.count; ++index2 {
                if(tmpStringArray[index] == String(orderedResolvedIssues[index2].date)) {
                    tmpInt = tmpInt + orderedResolvedIssues[index2].numberOfStorypoints
                }
            }
            tmpDoubleArray.append(tmpMaxStoryPoints - Double(tmpInt))
        }
        return tmpDoubleArray
    }
    
    func orderByDate(resolvedIssues : [ResolvedIssue]) -> [ResolvedIssue] {
        let tmpArray = resolvedIssues.sort { (res1, res2) -> Bool in
            return res2.date.isGreaterThanDate(res1.date)
        }
        return tmpArray
    }
    
    func uniq<S : SequenceType, T : Hashable where S.Generator.Element == T>(source: S) -> [T] {
        var buffer = [T]()
        var added = Set<T>()
        for elem in source {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }

    func filterIssuesByProject(resolvedIssues :[ResolvedIssue], project: String) -> [ResolvedIssue]{
        var tmpArray: [ResolvedIssue] = []
        for var index = 0; index < resolvedIssues.count; ++index {
            if(project == resolvedIssues[index].project.title) {
                tmpArray.append(resolvedIssues[index])
            }
        }
        return tmpArray
    }
    
    //Picker View Stuff
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return projects.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentProject = projectTitles[row]
        buildDiagramDataValues(resolvedIssues, project: currentProject)
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return projectTitles[row]
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
}

struct ResolvedIssue {
    var date : NSDate
    var numberOfStorypoints : Int
    var project : Project
    var sprintName : String
}

struct Project {
    var title : String
    var key : String
}

struct Issue {
    var storyPoints : String
    var project : String
    var doneDate :String
}

struct Sprint {
    var name : String
    var startDate : NSDate
    var endDate : NSDate
    var maxStoryPoints : Int?
    var project : Project

}
// MARK: Hashable
extension Sprint: Hashable {
    var hashValue: Int {
        return name.hashValue ^ project.hashValue
    }
}

// MARK: Equatable
func ==(lhs: Sprint, rhs: Sprint) -> Bool {
    return lhs.name == rhs.name && lhs.project == rhs.project
}

// MARK: Hashable
extension Project: Hashable {
    var hashValue: Int {
        return title.hashValue ^ key.hashValue
    }
}

// MARK: Equatable
func ==(lhs: Project, rhs: Project) -> Bool {
    return lhs.title == rhs.title && lhs.key == rhs.key
}

extension NSDate {
    func isGreaterThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    func isLessThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
    
    func equalToDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isEqualTo = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedSame {
            isEqualTo = true
        }
        
        //Return Result
        return isEqualTo
    }
    
    func addDays(daysToAdd: Int) -> NSDate {
        let secondsInDays: NSTimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded: NSDate = self.dateByAddingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    func addHours(hoursToAdd: Int) -> NSDate {
        let secondsInHours: NSTimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded: NSDate = self.dateByAddingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}