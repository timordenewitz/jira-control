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
    var storyPointCount = 0
    var currentProject : String = ""
    
    let storyPointKey = "customfield_10002"
    var issuesArray = [issue]()
    var resolvedIssues = [ResolvedIssue]()
    
    
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var pickerViewOutlet: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadIssues()
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
    
    func loadIssues() {
        print(serverAdress)
        Alamofire.request(.GET, serverAdress + "/rest/api/latest/search?jql=" + "project%20in%20projectsWhereUserHasRole(Developers)%20AND%20sprint%20in%20openSprints%20()%20AND%20(type=%20Aufgabe%20OR%20Type=%20Bug)")
            .responseJSON { response in
                if let JSON = response.result.value {
                    if let issues = JSON["issues"] {
                        //All Issues Reported by User
                        for var index = 0; index < issues!.count; ++index{
                            if let fields = issues![index]["fields"] {
                                if let projectArray = fields!["project"] {
                                    let tmpProject = Project(title: projectArray!["name"] as! String, key: projectArray!["key"] as! String, issues: nil)
                                        self.projects.insert(tmpProject)
                                    if let storyPointsJSON = fields![self.storyPointKey] {
                                        if (!(storyPointsJSON is NSNull)) {
                                            self.storyPointCount = self.storyPointCount + (storyPointsJSON?.integerValue!)!
                                            if let resolutionDateJSON = fields!["resolutiondate"] {
                                                if (!(resolutionDateJSON is NSNull)) {
                                                    var myStringArr = resolutionDateJSON!.componentsSeparatedByString("T")
                                                    let dateFormatter = NSDateFormatter()
                                                    dateFormatter.timeZone =  NSTimeZone(name: "UTC")
                                                    dateFormatter.dateFormat = "yyyy-MM-dd"
                                                    let date = dateFormatter.dateFromString(myStringArr[0])
                                                    self.resolvedIssues.append(ResolvedIssue(date: date!, numberOfStorypoints: storyPointsJSON!.integerValue!, project: tmpProject ))
                                                }
                                            }
                                        }
                                    }

                                }
                            }
                        }
                    }
                }
                self.pickerViewOutlet.reloadAllComponents()
                self.buildDiagramDataValues(self.resolvedIssues, project: self.currentProject)
        }

    }
    
    func buildDiagramDataValues(resolvedIssues : [ResolvedIssue], project : String) {
        let filteredIssues = filterIssuesByProject(resolvedIssues, project: project)
        let orderedResolvedIssues = orderByDate(filteredIssues)
        print(orderedResolvedIssues)
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
        
        for var index = 0; index < orderedResolvedIssues.count; ++index {
            tmpStringArray.append(String(orderedResolvedIssues[index].date))
        }
        tmpStringArray = uniq(tmpStringArray)
        tmpDoubleArray.append(Double(storyPointCount))

        
        for var index = 0; index < tmpStringArray.count; ++index {
            var tmpInt = 0
            for var index2 = 0; index2 < orderedResolvedIssues.count; ++index2 {
                if(tmpStringArray[index] == String(orderedResolvedIssues[index2].date)) {
                    tmpInt = tmpInt + orderedResolvedIssues[index2].numberOfStorypoints
                }
            }
            tmpDoubleArray.append(Double((storyPointCount - tmpInt)))
        }
        print(tmpDoubleArray)
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
        buildDiagramDataValues(resolvedIssues, project: currentProject)
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var tmpArray :[String] = []
        for project in projects {
            tmpArray.append(project.title)
        }
        currentProject = tmpArray[row]
        return tmpArray[row]
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
}

struct ResolvedIssue {
    var date :NSDate
    var numberOfStorypoints :Int
    var project : Project
}

struct Project {
    var title :String
    var key :String
    var issues: [issue]?
}

struct issue {
    var storyPoints :String
    var project : String
    var doneDate :String
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