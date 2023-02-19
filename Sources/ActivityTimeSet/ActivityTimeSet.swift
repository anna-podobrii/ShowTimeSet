//
//  ActivityTimeSet.swift
//  
//
//  Created by Anna Podobrii on 16.02.2023.
//

import Foundation

let lasVegasTimezone = "America/Las_Vegas"

public struct BusinessHour: Identifiable {
    var id: String { return listDisplay() }
    
    static var timeFormatter:DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("h:mp")
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter
    }
    let title: String
    let openHour: Int
    let openMinute: Int
    let closeHour: Int
    let closeMinute: Int
    let lastStartHour: Int?
    let lastStartMinute: Int?
    
    var hasLastSeating: Bool {
        return lastStartHour != nil && lastStartMinute != nil
    }
    
    func listDisplay(includeLastSeating: Bool = false, in topCategoryId: String? = nil) -> String {
        var listDisplay = ""
        let lastStartTitle = ActivityCategory.lastStartTitle(for: topCategoryId)
        
        if hasLastSeating && includeLastSeating {
            let closeTimeComponents = DateComponents(calendar: Calendar.current, hour: lastStartHour, minute: lastStartMinute)
            let displayClose = BusinessHour.timeFormatter.string(from: Calendar.current.date(from: closeTimeComponents) ?? Date())
            listDisplay.append("Last \(lastStartTitle) at \(displayClose)")
        } else {
            if openHour == 0 && openMinute == 0 && closeHour == 0 && closeMinute == 0 {
                listDisplay.append("Open 24 Hours")
                return listDisplay
            }
            if openHour == 0 && openMinute == 0 {
                listDisplay.append("Midnight-")
            } else {
                let openTimeComponents = DateComponents(calendar: Calendar.current, hour: openHour, minute: openMinute)
                let displayOpen = BusinessHour.timeFormatter.string(from: Calendar.current.date(from: openTimeComponents) ?? Date())
                
                listDisplay.append(displayOpen + "-")
            }
            if (closeHour == 0 && closeMinute == 0) || (closeHour == 24 && closeMinute == 0) {
                listDisplay.append("Midnight")
            } else {
                let closeTimeComponents = DateComponents(calendar: Calendar.current, hour: closeHour, minute: closeMinute)
                let displayClose = BusinessHour.timeFormatter.string(from: Calendar.current.date(from: closeTimeComponents) ?? Date())
                listDisplay.append(displayClose)
            }
        }
        return listDisplay.removingAMPMSpace()
    }
}

public struct BusinessIntervalList {
    let intervals: [BusinessHour]
    var operatingHours: String? = nil
    
}

public struct BusinessHourSet {
    let monHours: String?
    let tueHours: String?
    let wedHours: String?
    let thuHours: String?
    let friHours: String?
    let satHours: String?
    let sunHours: String?
    
    let tempClosed:Bool
    
    let mondayBusinessIntervals: BusinessIntervalList
    let tuesdayBusinessIntervals: BusinessIntervalList
    let wednesdayBusinessIntervals: BusinessIntervalList
    let thursdayBusinessIntervals: BusinessIntervalList
    let fridayBusinessIntervals: BusinessIntervalList
    let saturdayBusinessIntervals: BusinessIntervalList
    let sundayBusinessIntervals: BusinessIntervalList
    
    struct OperatingHours {
        var earliestHour: Int = 99
        var earliestMinute: Int = 61
        var latestHour: Int = -1
        var latestMinute: Int = -1
        var tempClosed: Bool = false
        
        mutating func capture(businessHours hours:BusinessHour) {
            if hours.openHour < earliestHour ||
                hours.openHour == earliestHour && hours.openMinute < earliestMinute {
                earliestHour = hours.openHour
                earliestMinute = hours.openMinute
            }
            if latestHour == 0 && latestMinute == 0 {
                return
            }
            if hours.closeHour > latestHour ||
                hours.closeHour == latestHour && hours.closeMinute > latestMinute {
                latestHour = hours.closeHour
                latestMinute = hours.closeMinute
            }
        }
        
        func operatingHoursString() -> String {
            if tempClosed { return "Temporarily Closed" }
            if earliestHour == 99 { return "Closed" }
            if earliestHour == 0 && earliestMinute == 0 && latestHour == 0 && latestMinute == 0 { return "Open 24 Hours"}
            
            var operatingHours: String = ""
            if earliestHour == 0 && earliestMinute == 0 {
                operatingHours.append("Midnight-")
            } else {
                let openTimeComponents = DateComponents(calendar: Calendar.current, hour: earliestHour, minute: earliestMinute)
                let displayOpen = BusinessHour.timeFormatter.string(from: Calendar.current.date(from: openTimeComponents) ?? Date())
                
                operatingHours.append(displayOpen + "-")
            }
            if (latestHour == 0 && latestMinute == 0) || (latestHour == 24 && latestMinute == 0) {
                operatingHours.append("Midnight")
            } else {
                let closeTimeComponents = DateComponents(calendar: Calendar.current, hour: latestHour, minute: latestMinute)
                let displayClose = BusinessHour.timeFormatter.string(from: Calendar.current.date(from: closeTimeComponents) ?? Date())
                operatingHours.append(displayClose)
            }
            return operatingHours.removingAMPMSpace()
        }
    }
    
    init(monHours: String?, tueHours: String?, wedHours: String?, thuHours: String?, friHours: String?, satHours: String?, sunHours: String?, tempClosed: Bool) {
        self.monHours = monHours
        self.tueHours = tueHours
        self.wedHours = wedHours
        self.thuHours = thuHours
        self.friHours = friHours
        self.satHours = satHours
        self.sunHours = sunHours
        self.tempClosed = tempClosed

        self.mondayBusinessIntervals = BusinessHourSet.businessIntervalList(from: monHours)
        self.tuesdayBusinessIntervals = BusinessHourSet.businessIntervalList(from: tueHours)
        self.wednesdayBusinessIntervals = BusinessHourSet.businessIntervalList(from: wedHours)
        self.thursdayBusinessIntervals = BusinessHourSet.businessIntervalList(from: thuHours)
        self.fridayBusinessIntervals = BusinessHourSet.businessIntervalList(from: friHours)
        self.saturdayBusinessIntervals = BusinessHourSet.businessIntervalList(from: satHours)
        self.sundayBusinessIntervals = BusinessHourSet.businessIntervalList(from: sunHours)
    }
    
    static let emptyBusinessHourSet: BusinessHourSet = {
        let emptySet = BusinessHourSet(monHours: nil, tueHours: nil, wedHours: nil, thuHours: nil, friHours: nil, satHours: nil, sunHours: nil, tempClosed: false)
        return emptySet
    }()
    
    
    public func hoursDisplay(for weekday: Weekday, weekdayIsToday today: Bool, rightNowDate: Date = Date()) -> String {
        
        if tempClosed == true { return "Temporarily Closed" }
        let comparisonBusinessIntervals = businessIntervalList(for: weekday.rawValue)
        
        //if BusinessHour instance for weekday is nil, return "Closed" + either "Today" or the
        //name of the weekday
        guard comparisonBusinessIntervals.hasOpenHours else {
            let closedOn = today ? " Today" : " " + weekday.weekdayName()
            return "Closed" + closedOn
        }
        
        // Special case: when open hours are 0:00 and close hours are 0:00, this
        // means that the activity is open 24 hours.
        if comparisonBusinessIntervals.open24Hours {
            return "Open 24 Hours"
        }
        
        var hoursDisplayString:String = "Closed"
        
        if comparisonBusinessIntervals.intervals.count > 1 {
            hoursDisplayString = (comparisonBusinessIntervals.operatingHours ?? "Closed") + "+"
        } else {
            if let hours = comparisonBusinessIntervals.intervals.first {
                // Determine open and close display hours
                let openTimeComponents = DateComponents(calendar: Calendar.current, hour: hours.openHour, minute: hours.openMinute)
                let closeTimeComponents = DateComponents(calendar: Calendar.current, hour: hours.closeHour, minute: hours.closeMinute)
                let displayOpen = BusinessHour.timeFormatter.string(from: Calendar.current.date(from: openTimeComponents) ?? Date())
                let displayClose = BusinessHour.timeFormatter.string(from: Calendar.current.date(from: closeTimeComponents) ?? Date())
                
                // if not today, return full hours
                guard today else {
                    if let lsHour = hours.lastStartHour, let lsMinute = hours.lastStartMinute {
                        let lastStartTimeComponents = DateComponents(calendar: Calendar.current, hour: lsHour, minute: lsMinute)
                        let displayLastStart = BusinessHour.timeFormatter.string(from: Calendar.current.date(from: lastStartTimeComponents) ?? Date())
                        hoursDisplayString = "\(displayOpen)-\(displayLastStart + "*")"
                    } else {
                        hoursDisplayString = "\(displayOpen)-\(displayClose)"
                    }
                    
                    return normalizedHours(from: hoursDisplayString)
                }
                
                let rightNowComponents = Calendar.current.dateComponents([.month, .day, .year, .hour, .minute, .timeZone], from: rightNowDate)
                
                let openComparisonComponents = DateComponents(calendar: Calendar.current, timeZone: TimeZone(identifier: lasVegasTimezone), era: nil, year: rightNowComponents.year, month: rightNowComponents.month, day: rightNowComponents.day, hour: hours.openHour, minute: hours.openMinute, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
                guard let openComparisonDate = Calendar.current.date(from: openComparisonComponents) else {
                    hoursDisplayString = "--"
                    return normalizedHours(from: hoursDisplayString)
                }
                
                let closeComparisonComponents = DateComponents(calendar: Calendar.current, timeZone: TimeZone(identifier: lasVegasTimezone), era: nil, year: rightNowComponents.year, month: rightNowComponents.month, day: rightNowComponents.day, hour: hours.closeHour, minute: hours.closeMinute, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
                guard let closeComparisonDate = Calendar.current.date(from: closeComparisonComponents) else {
                    hoursDisplayString = "--"
                    return normalizedHours(from: hoursDisplayString)
                }
                
                if rightNowDate <= openComparisonDate {
                    if let lsHour = hours.lastStartHour, let lsMinute = hours.lastStartMinute {
                        let lastStartTimeComponents = DateComponents(calendar: Calendar.current, hour: lsHour, minute: lsMinute)
                        let displayLastStart = BusinessHour.timeFormatter.string(from: Calendar.current.date(from: lastStartTimeComponents) ?? Date())
                        hoursDisplayString = "\(displayOpen)-\(displayLastStart + "*")"
                    } else {
                        hoursDisplayString = "\(displayOpen)-\(displayClose)"//.replacingOccurrences(of: " ", with: "")
                    }
                }
                
                if let lsHour = hours.lastStartHour, let lsMinute = hours.lastStartMinute {
                    let lastStartTimeComponents = DateComponents(calendar: Calendar.current, hour: lsHour, minute: lsMinute)
                    let displayLastStart = BusinessHour.timeFormatter.string(from: Calendar.current.date(from: lastStartTimeComponents) ?? Date())
                    
                    let lastStartComparisonComponents = DateComponents(calendar: Calendar.current, timeZone: TimeZone(identifier: lasVegasTimezone), year: rightNowComponents.year, month: rightNowComponents.month, day: rightNowComponents.day, hour: lsHour, minute: lsMinute)
                    if let lastStartComparisonDate = Calendar.current.date(from: lastStartComparisonComponents) {
                        
                        if openComparisonDate < rightNowDate && rightNowDate <= lastStartComparisonDate {
                            
                            //last start < 1 hr
                            hoursDisplayString = "Last at \(displayLastStart)"
                        }
                        if rightNowDate > lastStartComparisonDate {
                            hoursDisplayString = "Last was \(displayLastStart)"
                        }
                    }
                } else {
                    if openComparisonDate < rightNowDate && rightNowDate <= closeComparisonDate {
                        hoursDisplayString = "Closes at \(displayClose)"
                        return normalizedHours(from: hoursDisplayString)
                    }
                }
                if rightNowDate > closeComparisonDate {
                    hoursDisplayString = "Closed at \(displayClose)"
                }
            }
        }
        return normalizedHours(from: hoursDisplayString)
    }
}
