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
    
    let storyPointKey = "customfield_10002"
    let sprintInfoField = "customfield_10005"
    var issuesArray = [Issue]()
    var resolvedIssues = [Issue]()
    
    let searchQuery="sprint in openSprints()"
    let maxResultsParameters = "&maxResults=5000"
    
    var projectTitles :[String] = []
    var touchArray = [DeepPressGestureRecognizer]()
    var index = 0
    let zoomThresehold :CGFloat = 0.95
    
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var pickerViewOutlet: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkConnection()
        let deepPressGestureRecognizer = DeepPressGestureRecognizer(target: self, action: "deepPressHandler:", threshold: 0.8)
        lineChartView.addGestureRecognizer(deepPressGestureRecognizer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        configureLineChartView()
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
                        self.loadProjects()

                    }
                }
        }
    }
    
    func loadProjects() {
        Alamofire.request(.GET, serverAdress + "/rest/api/latest/search?jql=" + searchQuery.stringByReplacingOccurrencesOfString(" ", withString: "%20") + maxResultsParameters)
            .responseJSON { response in

                if let JSON = response.result.value {
                    if let issues = JSON["issues"] {
                        //All Issues Reported by User
                        for var index = 0; index < issues!.count; ++index {
                            var tmpProject : Project
                            if let fields = issues![index]["fields"] {
                                if let projectArray = fields!["project"] {
                                    tmpProject = Project(title: projectArray!["name"] as! String, key: projectArray!["key"] as! String, sprints: nil)
                                    self.projects.insert(tmpProject)
                                    if let sprintInfo = fields![self.sprintInfoField] {
                                        for var index = 0; index < sprintInfo!.count; ++index {
                                            var myTempStrArray = sprintInfo![index].componentsSeparatedByString(",")
                                            if (self.checkSprintObjectForNullValues(myTempStrArray)) {
                                                let sprintState = myTempStrArray[2].componentsSeparatedByString("=")[1]
                                                let sprintName = myTempStrArray[3].componentsSeparatedByString("=")[1]
                                                let sprintStartDate = self.getDateFromObject(myTempStrArray[4].componentsSeparatedByString("=")[1])
                                                let sprintEndDate = self.getDateFromObject(myTempStrArray[5].componentsSeparatedByString("=")[1])
                                                if (sprintState == "ACTIVE"){
                                                    self.sprints.insert(Sprint(name: sprintName, startDate: sprintStartDate, endDate: sprintEndDate, maxStoryPoints: 0, project: tmpProject))

                                                }
                                            }
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
                                            if let sprintInfo = fields![self.sprintInfoField] {
                                                for var index = 0; index < sprintInfo!.count; ++index {
                                                    var myTempStrArray = sprintInfo![index].componentsSeparatedByString(",")
                                                    let sprintName = myTempStrArray[3].componentsSeparatedByString("=")[1]
                                                    for sprintObject in self.sprints {
                                                        if (sprintObject.name == sprintName && sprintObject.project.key == (projectArray!["key"] as! String)) {
                                                            if let resolutionDateJSON = fields!["resolutiondate"] {
                                                                if (!(resolutionDateJSON is NSNull)) {
                                                                    let date = self.getDateFromObject(resolutionDateJSON! as! String)
                                                                    self.resolvedIssues.append(Issue(date: date, numberOfStorypoints: storyPointsJSON!.integerValue!, project: self.getProjectByName(projectArray!["name"] as! String)!, sprintName: sprintName))

                                                                } else {
                                                                    self.issuesArray.append(Issue(numberOfStorypoints: storyPointsJSON!.integerValue!, project: self.getProjectByName(projectArray!["name"] as! String)!, sprintName: sprintName))
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
                        self.buildDiagramDataValues(self.resolvedIssues, project: (self.projects.first)!)
                    }
                }
        }
    }
    
    func checkSprintObjectForNullValues(myTempStrArray : [String]) -> Bool {
        var ret = true
        
        if (myTempStrArray[4].componentsSeparatedByString("=")[1] == "<null>" || myTempStrArray[5].componentsSeparatedByString("=")[1] == "<null>" ) {
            ret = false
        }
        return ret
    }
    
    func computeMaxStorypointForSprint() {
        for issueObject in issuesArray {
            for sprintObject in sprints {
                if (sprintObject.name == issueObject.sprintName  && sprintObject.project.key == issueObject.project.key) {
                    var tmpSprint = sprintObject
                    sprints.remove(sprintObject)
                    tmpSprint.maxStoryPoints = tmpSprint.maxStoryPoints! + issueObject.numberOfStorypoints
                    sprints.insert(tmpSprint)
                }
            }
        }

        for issueObject in resolvedIssues {
            for sprintObject in sprints {
                if (sprintObject.name == issueObject.sprintName  && sprintObject.project.key == issueObject.project.key) {
                    var tmpSprint = sprintObject
                    sprints.remove(sprintObject)
                    tmpSprint.maxStoryPoints = tmpSprint.maxStoryPoints! + issueObject.numberOfStorypoints
                    sprints.insert(tmpSprint)
                }
            }
        }
    }
    
    func getDateFromObject(dateObject : String) -> NSDate {
        var myStringArr = dateObject.componentsSeparatedByString("T")
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone =  NSTimeZone(name: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.dateFromString(myStringArr[0])!
    }
    
    func createProjectsArray() {
        for project in projects {
            var tmpProject = project
            projects.remove(project)
            for sprint in sprints {
                if (sprint.project == project) {
                    tmpProject.sprints?.append(sprint)
                }
            }
            projects.insert(tmpProject)
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
    
    func buildDiagramDataValues(resolvedIssues : [Issue], project : Project) {
        let filteredResolvedIssues = filterIssuesByProject(resolvedIssues, project: project.title)
        let orderedResolvedIssues = orderByDate(filteredResolvedIssues)
        let burndownDates = getDatesInSprintTillToday(project, resolvedIssues : orderedResolvedIssues)
        let nrOfDatesInSprint = getDatesInSprintTillEnd(project).count
        let xAxisDataSet = buildXAxisDataSet(burndownDates)
        let valueDataSet = buildValueDataSet(orderedResolvedIssues, burndownDates: burndownDates, project: project)
        setChart(xAxisDataSet, values: valueDataSet, sprintLength: nrOfDatesInSprint)
    }
    
    func orderByDate(resolvedIssues : [Issue]) -> [Issue] {
        let tmpArray = resolvedIssues.sort { (res1, res2) -> Bool in
            return res2.date!.isGreaterThanDate(res1.date!)
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
    
    func filterIssuesByProject(resolvedIssues :[Issue], project: String) -> [Issue]{
        var tmpArray: [Issue] = []
        for var index = 0; index < resolvedIssues.count; ++index {
            if(project == resolvedIssues[index].project.title) {
                tmpArray.append(resolvedIssues[index])
            }
        }
        return tmpArray
    }
    
    func buildXAxisDataSet(burndownDates : [burndownDate]) -> [String] {
        var tmpArray :[String] = []
        tmpArray.append("START")
        for date in burndownDates {
            tmpArray.append((date.date?.dateStringWithFormat("dd/MM/yyyy"))!)
        }
        return tmpArray
    }
    
    func buildValueDataSet(orderedResolvedIssues : [Issue], burndownDates: [burndownDate], project : Project) -> [Double] {
        var tmpDoubleArray : [Double] = []
        var tmpMaxStoryPoints = 0.0
        
        for sprintObject in sprints {
            if (sprintObject.project.key == project.key) {
                tmpMaxStoryPoints = Double(sprintObject.maxStoryPoints!)
            }
        }
        
        tmpDoubleArray.append(tmpMaxStoryPoints)
        
        for date in burndownDates {
            var tmpStoryPoints = 0
            
            if(burndownDates.count == 1 && orderedResolvedIssues.count == 0) {
                return(tmpDoubleArray)
            }
            for resolvedIssue in orderedResolvedIssues {
                if(date.date!.equalToDate(resolvedIssue.date!)) {
                    tmpStoryPoints = tmpStoryPoints + resolvedIssue.numberOfStorypoints
                }
            }
            if (tmpDoubleArray.count == 0) {
                tmpDoubleArray.append(tmpMaxStoryPoints - Double(tmpStoryPoints))
            } else {
                tmpDoubleArray.append(tmpDoubleArray[tmpDoubleArray.count - 1] - Double(tmpStoryPoints))
            }
        }
        return tmpDoubleArray
    }

    
    func setChart(dataPoints: [String], values: [Double], sprintLength : Int) {
        lineChartView.noDataText = "You need to provide data for the chart."
        var dataEntries: [ChartDataEntry] = []
        var dataEntriesBurndownMean: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        let burndownMeanValues = buildBurndownMeanLine(values[0], nrOfDataPoints: dataPoints.count, sprintLength : sprintLength)
        
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: burndownMeanValues[i], xIndex: i)
            dataEntriesBurndownMean.append(dataEntry)
        }
        
        let lineChartDataSet = buildDataSet(dataEntries)
        let lineChartDataSet2 = buildBurndownGuidlineDataSet(dataEntriesBurndownMean)
        
        var dataSets : [LineChartDataSet] = [LineChartDataSet]()
        dataSets.append(lineChartDataSet)
        dataSets.append(lineChartDataSet2)
        
        let lineChartData = LineChartData(xVals: dataPoints, dataSets: dataSets)
        lineChartView.data = lineChartData
    }
    
    func configureLineChartView() {
        lineChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        lineChartView.xAxis.labelPosition = .Bottom
        let yAxisRight = lineChartView.getAxis(ChartYAxis.AxisDependency.Right)
        let yAxisLeft = lineChartView.getAxis(ChartYAxis.AxisDependency.Left)
        yAxisRight.drawLabelsEnabled = false
        lineChartView.opaque = false
        lineChartView.backgroundColor = UIColor.clearColor()
        lineChartView.xAxis.axisLineColor = UIColor.whiteColor()
        lineChartView.xAxis.axisLineWidth = 2.0
        yAxisLeft.axisLineColor = UIColor.whiteColor()
        yAxisLeft.axisLineWidth = 2.0
        lineChartView.xAxis.labelTextColor = UIColor.whiteColor()
        yAxisLeft.labelTextColor = UIColor.whiteColor()
        yAxisLeft.gridColor = UIColor.whiteColor()
        lineChartView.xAxis.gridColor = UIColor.whiteColor()
        lineChartView.infoTextColor = UIColor.whiteColor()
        lineChartView.descriptionTextColor = UIColor.whiteColor()
        lineChartView.gridBackgroundColor = UIColor.redColor()
        lineChartView.legend.textColor = UIColor.whiteColor()
    }
    
    func buildDataSet(dataEntries : [ChartDataEntry]) -> LineChartDataSet{
        let lineChartDataSet = LineChartDataSet(yVals: dataEntries, label: "Story Points Remaining")
        lineChartDataSet.axisDependency = .Left // Line will correlate with left axis values
        lineChartDataSet.setColor(UIColor.jiraCommanderBlue())
        lineChartDataSet.setCircleColor(UIColor.jiraCommanderBlue())
        lineChartDataSet.lineWidth = 8.0
        lineChartDataSet.circleRadius = 8.0
        lineChartDataSet.fillAlpha = 65 / 255.0
        lineChartDataSet.fillColor = UIColor.jiraCommanderBlue()
        lineChartDataSet.highlightColor = UIColor.jiraCommanderBlue()
        lineChartDataSet.drawCircleHoleEnabled = true
        lineChartDataSet.valueFont = UIFont(descriptor: UIFontDescriptor(name: "Helvetica", size: 0.0), size: 0.0)
        return lineChartDataSet
    }
    
    func buildBurndownGuidlineDataSet(dataEntries : [ChartDataEntry]) -> LineChartDataSet{
        let lineChartDataSet2 = LineChartDataSet(yVals: dataEntries, label: "Guidline")
        lineChartDataSet2.axisDependency = .Left // Line will correlate with left axis values
        lineChartDataSet2.setColor(UIColor.whiteColor().colorWithAlphaComponent(0.5))
        lineChartDataSet2.setCircleColor(UIColor.whiteColor())
        lineChartDataSet2.lineWidth = 2.0
        lineChartDataSet2.circleRadius = 0.0
        lineChartDataSet2.fillAlpha = 65 / 255.0
        lineChartDataSet2.fillColor = UIColor.whiteColor()
        lineChartDataSet2.highlightColor = UIColor.whiteColor()
        lineChartDataSet2.drawCircleHoleEnabled = true
        lineChartDataSet2.valueFont = UIFont(descriptor: UIFontDescriptor(name: "Helvetica", size: 0.0), size: 0.0)
        return lineChartDataSet2
    }
    
    func buildBurndownMeanLine(maxSP : Double, nrOfDataPoints : Int, sprintLength : Int) -> [Double]{
        var ret : [Double] = []
        let storyPointsPerDay = maxSP/Double(sprintLength)
        for var i = 0; i < nrOfDataPoints; ++i {
            ret.append(maxSP - Double(i) * storyPointsPerDay)
        }
        return ret
    }

    
    func getDatesInSprintTillToday(project : Project, resolvedIssues : [Issue]) ->[burndownDate]{
        var ret : [burndownDate] = []
        for sprint in sprints {
            if(sprint.project == project) {
                NSCalendar.currentCalendar()
                for var date = sprint.startDate; date.isLessThanDate(NSDate()); date = date.addDays(1) {
                    if(!date.inWeekend) {
                        ret.append(burndownDate(date: date, numberOfStorypoints: 0))
                    }
                }
            }
        }
        if(ret.count == 1 && resolvedIssues.count == 0) {
            ret.removeAll()
        }
        return ret
    }
    
    func getDatesInSprintTillEnd(project : Project) ->[burndownDate]{
        var ret : [burndownDate] = []
        for sprint in sprints {
            if(sprint.project == project) {
                for var date = sprint.startDate; date.isLessThanDate(sprint.endDate); date = date.addDays(1) {
                    if(!date.inWeekend) {
                        ret.append(burndownDate(date: date, numberOfStorypoints: 0))
                    }
                }
            }
        }
        return ret
    }
    
    //Picker View Stuff
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return projects.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        for project in projects {
            if (project.title == projectTitles[row]) {
                buildDiagramDataValues(resolvedIssues, project: project)
            }
        }
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 25.0
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let attributedString = NSAttributedString(string: projectTitles[row], attributes: [NSForegroundColorAttributeName : UIColor.whiteColor()])
        return attributedString
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func deepPressHandler(recognizer: DeepPressGestureRecognizer) {

        if(recognizer.state == .Began) {
        }
        
        if(recognizer.state == .Changed) {
            touchArray.append(recognizer)
            guard touchArray.count > 7 else {
                lineChartView.zoom((zoomThresehold + recognizer.force / 10), scaleY: (zoomThresehold + recognizer.force / 10) , x: recognizer.xTouch, y: recognizer.yTouch)
                index++
                return
            }
            let point1 = lineChartView.getEntryByTouchPoint(touchArray[0].point!)
            let point2 = lineChartView.getPosition(point1, axis: ChartYAxis.AxisDependency.Left)
            lineChartView.zoom((zoomThresehold + touchArray[touchArray.count - 7].force / 12), scaleY: (zoomThresehold + touchArray[touchArray.count - 7].force / 12) , x: point2.x * touchArray[touchArray.count - 7].force, y: point2.y * touchArray[touchArray.count - 7].force * 1.3)
        }
        
        if(recognizer.state == .Ended) {
            touchArray.removeAll()
        }
    }
}

struct Project {
    var title : String
    var key : String
    var sprints : [Sprint]?
}

struct burndownDate {
    var date : NSDate?
    var numberOfStorypoints : Int
}

struct Issue {
    var date : NSDate?
    var numberOfStorypoints : Int
    var project : Project
    var sprintName : String
    
    init(numberOfStorypoints: Int, project : Project, sprintName : String) {
        self.numberOfStorypoints = numberOfStorypoints
        self.project = project
        self.sprintName = sprintName
    }
    
    init(date : NSDate, numberOfStorypoints: Int, project : Project, sprintName : String) {
        self.date = date
        self.numberOfStorypoints = numberOfStorypoints
        self.project = project
        self.sprintName = sprintName
    }
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
    
    func dateStringWithFormat(format: String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.stringFromDate(self)
    }
    
    var inWeekend: Bool {
        let calendar = NSCalendar.currentCalendar()
        return calendar.isDateInWeekend(self)
    }
}

extension UIColor {
    static func jiraCommanderBlue() -> UIColor {
        return UIColor(red: 74/255, green: 157/255, blue: 218/255, alpha: 0.9)
    }
}