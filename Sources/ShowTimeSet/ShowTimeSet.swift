import Foundation


public struct ShowTimeSet {
    public private(set) var text = "Hello, World!"
    let mondayShowTimes: ShowEventTimeList
    let tuesdayShowTimes: ShowEventTimeList
    let wednesdayShowTimes: ShowEventTimeList
    let thursdayShowTimes: ShowEventTimeList
    let fridayShowTimes: ShowEventTimeList
    let saturdayShowTimes: ShowEventTimeList
    let sundayShowTimes: ShowEventTimeList
    
    let dateSpecificShowTimes: [DateInterval: ShowEventTimeList]
    let dateSpecificShowDatesAndTimesDisplaySet: [Date: ShowEventTimeList]
    
    public init(monTimes: String?, tueTimes: String?, wedTimes: String?, thuTimes: String?, friTimes: String?, satTimes: String?, sunTimes: String?, dateSpecificTimes: [String]?) {
        self.mondayShowTimes = ShowTimeSet.showEventTimeList(from: monTimes)
        self.tuesdayShowTimes = ShowTimeSet.showEventTimeList(from: tueTimes)
        self.wednesdayShowTimes = ShowTimeSet.showEventTimeList(from: wedTimes)
        self.thursdayShowTimes = ShowTimeSet.showEventTimeList(from: thuTimes)
        self.fridayShowTimes = ShowTimeSet.showEventTimeList(from: friTimes)
        self.saturdayShowTimes = ShowTimeSet.showEventTimeList(from: satTimes)
        self.sundayShowTimes = ShowTimeSet.showEventTimeList(from: sunTimes)
        dateSpecificShowTimes = ShowTimeSet.dateSpecificShowEventTimeList(from: dateSpecificTimes)
        dateSpecificShowDatesAndTimesDisplaySet = ShowTimeSet.calculateDateSpecificShowDatesAndTimesDisplaySet(from: dateSpecificShowTimes)
    }
    
    internal static func showEventTimeList(from timesString: String?) -> ShowEventTimeList {
        guard let timesString = timesString else {
            return ShowEventTimeList(showTimes: [])
        }
        
        let timesToParse:[String] = timesString.components(separatedBy: ",")
        var showEventTimes:[ShowEventTime] = []
        
        for showtimeString in timesToParse {
            guard showtimeString.contains(":") else {
                continue
            }
            
            let timeParts:[String] = showtimeString.components(separatedBy: ":")
            
            guard let title = timeParts.first,
                  let timeString = timeParts.last else {
                continue
            }
            
            let startHourString = timeString.prefix(2)
            let startMinuteString = timeString.suffix(2)
            
            guard let startHour = Int(startHourString),
                  let startMinute = Int(startMinuteString) else {
                continue
            }
            
            let showEventTime = ShowEventTime(title: title, startHour: startHour, startMinute: startMinute)
            showEventTimes.append(showEventTime)
        }
        
        let times = ShowEventTimeList(showTimes: showEventTimes)
        return times
    }
    
    internal static func dateSpecificShowEventTimeList(from dateSpecificTimesStrings: [String]?) -> [DateInterval : ShowEventTimeList] {
        
        var dateSpecificShowEventTimeList: [DateInterval: ShowEventTimeList] = [:]
        
        // ["2021-10-26,@ Colorado Avalanche:1900", "2021-10-27,@ Dallas Stars:1900"]
        // ["2021-10-21|2021-10-28,:","2021-10-31,:","2021-12-3|2021-12-11,:"]
        // ["2021-10-27|2021-10-31,:"]
        // ["2021-11-23,:1700,:2000","2021-11-24|2021-11-26,:1400,:1700,:2000"]
        // ["2021-10-20,:1930","2021-10-22,:1930","2021-10-23,:1930"]

        // for each string
        //   separate by ',' - first part is date, subsequent parts are titles and times
        //   first part, separate by '|' - first is start date, last is (optional) end date
        //   subsequent parts, separate by ':' - first is title, second is time
        //   for each date (start date to end date) add show event time list
        //     to dateSpecificShowEventTimeList

        for dateTimeString in dateSpecificTimesStrings ?? [] {
            
            var datesAndTimesToParse:[String] = dateTimeString.components(separatedBy: ",")
            guard let dateRangeString = datesAndTimesToParse.first,
                  let dateRange = dateRange(from: dateRangeString) else { continue }
            
            datesAndTimesToParse.remove(at: 0)
            let timesString = datesAndTimesToParse.joined(separator: ",")
            
            dateSpecificShowEventTimeList[dateRange] = showEventTimeList(from: timesString)
        }
        
        return dateSpecificShowEventTimeList
    }
    
    private static func calculateDateSpecificShowDatesAndTimesDisplaySet(from dateIntervalsAndShowTimes: [DateInterval:ShowEventTimeList]) -> [Date: ShowEventTimeList] {
        guard dateIntervalsAndShowTimes.count > 0 else {
            return [:]
        }
        
        var dateAndTimesList: [Date: ShowEventTimeList] = [:]
        
        let todayDate = NSCalendar.current.startOfDay(for: Date())
        for (dateInterval, showTimeList) in dateIntervalsAndShowTimes {
            let dates = dateInterval.datesInInterval()
            for date in dates {
                if date >= todayDate {
                    dateAndTimesList[date] = showTimeList
                }
            }
        }
        
        return dateAndTimesList
    }
    
    private static let iso8601DateFormatter: ISO8601DateFormatter = ISO8601DateFormatter()

    internal static func dateRange(from dateString: String) -> DateInterval? {
        let datesToParse:[String] = dateString.components(separatedBy: "|")
        
        var firstDate: Date? = nil
        if var firstDateString = datesToParse.first {
            firstDateString.append(contentsOf: "T00:00:00-0800")
            firstDate = ShowTimeSet.iso8601DateFormatter.date(from: firstDateString)
        }
        var secondDate: Date? = nil
        if datesToParse.count > 1, var secondDateString = datesToParse.last {
            secondDateString.append(contentsOf: "T23:59:59-0800")
            secondDate = ShowTimeSet.iso8601DateFormatter.date(from: secondDateString)
        }
        
        if let actualFirstDate = firstDate, secondDate == nil {
            let oneDay: Double = 23.0 * 60.0 * 60.0 + 60.0 * 59.0 + 59.0
            return DateInterval(start: actualFirstDate, duration: oneDay)
        }
        if let actualFirstDate = firstDate, let actualSecondDate = secondDate {
            if actualSecondDate < actualFirstDate {
                print("DateInterval error: \(actualSecondDate) is before \(actualFirstDate), returning nil date range")
                return nil
            }
            return DateInterval(start: actualFirstDate, end: actualSecondDate)
        }
        return nil
    }
    
    public static func convertMidnightAndNoon(in timeString: String) -> String {
        let convertMidnight = timeString.replacingOccurrences(of: "12:00am", with: "Midnight")
        let convertNoon = convertMidnight.replacingOccurrences(of: "12:00pm", with: "Noon")
        return convertNoon
    }
    
    static func removingAMPMSpace(from timeString:String) -> String {
        return timeString.replacingOccurrences(of: " am", with: "am").replacingOccurrences(of: " pm", with: "pm").replacingOccurrences(of: ":00", with: "")
    }
    
    public func showHoursDisplay(for weekday: Weekday, weekdayIsToday today: Bool, rightNowDate: Date = Date()) -> String {
        guard hasShowTimesForDay(for: weekday, comparisonDate: rightNowDate) else {
            return "No Times"
        }
        
        // Get base show time list
        var comparisonShowTimes: ShowEventTimeList = showEventTimeList(for: weekday.rawValue)
        // Check if there are date-specific show times
        for (dateInterval, showTimeList) in dateSpecificShowTimes {
            if let endOfComparisonDate = rightNowDate.endOfDay, dateInterval.contains(endOfComparisonDate) {
                comparisonShowTimes = showTimeList
                break
            }
        }

        var hoursDisplayString:String = ""
        for showTime in comparisonShowTimes.showTimes {
            hoursDisplayString.append("\(showTime.listDisplay()) ")
        }
        
        return ShowTimeSet.convertMidnightAndNoon(in: ShowTimeSet.removingAMPMSpace(from: hoursDisplayString))
    }
  
    
    func showEventTimeList(for weekday:Int) -> ShowEventTimeList {
        switch weekday {
        case 1:
            return sundayShowTimes
        case 2:
            return mondayShowTimes
        case 3:
            return tuesdayShowTimes
        case 4:
            return wednesdayShowTimes
        case 5:
            return thursdayShowTimes
        case 6:
            return fridayShowTimes
        case 7:
            return saturdayShowTimes
        default:
            return ShowEventTimeList(showTimes: [])
        }
    }
    
    func hasShowTimesForDay(for weekday: Weekday, comparisonDate: Date = Date()) -> Bool {
        // LOGIC:
        // Step 1: Evaluate whether any date-specific showtimes match the comparison date. If so, return true if showtimes, otherwise false (dark).
        // Step 2: Determine if there are showtimes for the specified weekday.
        
        // Step 1.
        for (dateInterval, showTimeList) in dateSpecificShowTimes {
            if let endOfComparisonDate = comparisonDate.endOfDay, dateInterval.contains(endOfComparisonDate) {
                return showTimeList.hasShowTimes
            }
        }
        
        // Step 2.
        let showTimeList = showEventTimeList(for: weekday.rawValue)
        if showTimeList.hasShowTimes {
            return true
        }
                
        return false
    }

}


public struct ShowEventTime {
    
    static var timeFormatter:DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("h:mp")
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter
    }
    let title: String
    let startHour: Int
    let startMinute: Int

    func listDisplay() -> String {
        var listDisplay = ""
        
        if title.count > 0 {
            listDisplay.append(title + ": ")
        }
        if startHour == 0 && startMinute == 0 {
            listDisplay.append("Midnight")
        } else {
            let startTimeComponents = DateComponents(calendar: Calendar.current, hour: startHour, minute: startMinute)
            let displayStart = ShowEventTime.timeFormatter.string(from: Calendar.current.date(from: startTimeComponents) ?? Date())
            listDisplay.append(displayStart)
        }

        return listDisplay
    }
}

public struct ShowEventTimeList {
    let showTimes: [ShowEventTime]
    
    var firstTime: ShowEventTime? {
        return showTimes.sorted { leftTime, rightTime in
            if leftTime.startHour == rightTime.startHour {
                return leftTime.startMinute < rightTime.startMinute
            }
            return leftTime.startHour < rightTime.startHour
        }.first
    }
    
    var hasShowTimes: Bool {
        return showTimes.count >= 1
    }
    
    var showHoursDisplay: String {
        var hoursDisplayString:String = ""
        for showTime in showTimes {
            hoursDisplayString.append("\(showTime.listDisplay()) ")
        }
        
        return ShowTimeSet.convertMidnightAndNoon(in: ShowTimeSet.removingAMPMSpace(from: hoursDisplayString))
    }
    
    var showHoursDisplaySet: [String] {
        var hoursDisplayStrings:[String] = []
        for showTime in showTimes {
            hoursDisplayStrings.append("\(showTime.listDisplay())")
        }
        
        return hoursDisplayStrings
    }
}



// Activity//

enum OpenStatus {
    case open
    case partialAM
    case partialPM
    case closed
}

let lasVegasTimezone = "America/Las_Vegas"

public struct BusinessHour: Identifiable {
    public var id: String { return listDisplay() }
    
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
        
        if hasLastSeating && includeLastSeating {
            let closeTimeComponents = DateComponents(calendar: Calendar.current, hour: lastStartHour, minute: lastStartMinute)
            let displayClose = BusinessHour.timeFormatter.string(from: Calendar.current.date(from: closeTimeComponents) ?? Date())
            listDisplay.append("Last at \(displayClose)")
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
        return listDisplay.replacingOccurrences(of: " am", with: "am").replacingOccurrences(of: " pm", with: "pm")
    }
}


struct BusinessIntervalList {
    let intervals: [BusinessHour]
    var operatingHours: String? = nil

    func openStatus(withPreviousDayIntervalList intervalList: BusinessIntervalList) -> OpenStatus {
        if intervals.count > 0 {
            if intervals.count == 1 && intervalList.hasNextDayCloseHour, let checkInterval = intervals.first {
                if checkInterval.openHour == 0 && checkInterval.openMinute == 0 { return .partialAM }
            }
            return .open
        } else {
            if intervalList.hasNextDayCloseHour { return .partialAM }
            return .closed
        }
    }
    
    var hasOpenHours: Bool {
        return intervals.count > 0
    }
    
    var open24Hours: Bool {
        var open = false
        
        for interval in intervals {
            if interval.openHour == 0 && interval.openMinute == 0 && interval.closeHour == 0 && interval.closeMinute == 0 {
                open = true
                break
            }
        }
        
        return open
    }
    
    var hasNextDayCloseHour: Bool {
        var containsNextDayCloseHour = false
        for interval in intervals {
            if (interval.closeHour > 24) || (interval.closeHour == 24 && interval.closeMinute > 0) {
                containsNextDayCloseHour = true
                break
            }
        }
        return containsNextDayCloseHour
    }
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
            return operatingHours.replacingOccurrences(of: " am", with: "am").replacingOccurrences(of: " pm", with: "pm")
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
    
    private static func businessIntervalList(from hoursString: String?) -> BusinessIntervalList {
        
        guard let hoursString = hoursString else {
            return BusinessIntervalList(intervals: [])
        }

        var operatingHours = OperatingHours()

        let intervalsToParse:[String] = hoursString.components(separatedBy: ",")
        var intervals:[BusinessHour] = []
        
        for interval in intervalsToParse {
            guard interval.contains(":") else {
                continue
            }
            
            let intervalParts:[String] = interval.components(separatedBy: ":")
            
            guard let title = intervalParts.first,
                  let hoursString = intervalParts.last,
                  hoursString.contains("-"),
                  let intervalHours = intervalParts.last?.components(separatedBy: "-"),
                  let openString = intervalHours.first,
                  let closeString = intervalHours.last else {
                continue
            }
            
            let openHourString = openString.prefix(2)
            let openMinuteString = openString.suffix(2)
            
            let closeHourString = closeString.prefix(2)
            let closeMinuteString = closeString.suffix(2)
            
            var lastSeatingHourString: String? = nil
            var lastSeatingMinuteString: String? = nil
            if intervalHours.count == 3 {
                let lastSeatingString = intervalHours[1]
                lastSeatingHourString = String(lastSeatingString.prefix(2))
                lastSeatingMinuteString = String(lastSeatingString.suffix(2))
            }

            guard let openHour = Int(openHourString),
                  let openMinute = Int(openMinuteString),
                  let closeHour = Int(closeHourString),
                  let closeMinute = Int(closeMinuteString) else {
                continue
            }
            
            let businessHour = BusinessHour(title: title, openHour: openHour, openMinute: openMinute, closeHour: closeHour, closeMinute: closeMinute, lastStartHour: Int(lastSeatingHourString ?? "notAnInt"), lastStartMinute: Int(lastSeatingMinuteString ?? "notAnInt"))
            intervals.append(businessHour)
            
            if openHour == 0 && openMinute == 0 && (closeHour != 0 || closeMinute != 0) {
                continue
            }
            
            operatingHours.capture(businessHours: businessHour)
        }
        
        return BusinessIntervalList(intervals: intervals, operatingHours: operatingHours.operatingHoursString())
    }

var openMonday: OpenStatus {
    get {
        if tempClosed == true { return .closed }
        return mondayBusinessIntervals.openStatus(withPreviousDayIntervalList: sundayBusinessIntervals)
    }
}

var openTuesday: OpenStatus {
    get {
        if tempClosed == true { return .closed }
        return tuesdayBusinessIntervals.openStatus(withPreviousDayIntervalList: mondayBusinessIntervals)
    }
}
var openWednesday: OpenStatus {
    get {
        if tempClosed == true { return .closed }
        return wednesdayBusinessIntervals.openStatus(withPreviousDayIntervalList: tuesdayBusinessIntervals)
    }
}
var openThursday: OpenStatus {
    get {
        if tempClosed == true { return .closed }
        return thursdayBusinessIntervals.openStatus(withPreviousDayIntervalList: wednesdayBusinessIntervals)
    }
}
var openFriday: OpenStatus {
    get {
        if tempClosed == true { return .closed }
        return fridayBusinessIntervals.openStatus(withPreviousDayIntervalList: thursdayBusinessIntervals)
    }
}
var openSaturday: OpenStatus {
    get {
        if tempClosed == true { return .closed }
        return saturdayBusinessIntervals.openStatus(withPreviousDayIntervalList: fridayBusinessIntervals)
    }
}
var openSunday: OpenStatus {
    get {
        if tempClosed == true { return .closed }
        return sundayBusinessIntervals.openStatus(withPreviousDayIntervalList: saturdayBusinessIntervals)
    }
}

func weekdayPrevious(to weekday:Int) -> Int {
    switch weekday {
    case 1:
        return 7
    default:
        return weekday - 1
    }
}

func businessIntervalList(for weekday:Int) -> BusinessIntervalList {
    switch weekday {
    case 1:
        return sundayBusinessIntervals
    case 2:
        return mondayBusinessIntervals
    case 3:
        return tuesdayBusinessIntervals
    case 4:
        return wednesdayBusinessIntervals
    case 5:
        return thursdayBusinessIntervals
    case 6:
        return fridayBusinessIntervals
    case 7:
        return saturdayBusinessIntervals
    default:
        return BusinessIntervalList(intervals: [])
    }
}

    func convertMidnightAndNoon(in timeString: String) -> String {
        let convertMidnight = timeString.replacingOccurrences(of: "12:00am", with: "Midnight")
        let convertNoon = convertMidnight.replacingOccurrences(of: "12:00pm", with: "Noon")
        return convertNoon
    }
    
    private func normalizedHours(from hoursString: String) -> String {
        let ampmAdjustedString = hoursString.replacingOccurrences(of: " am", with: "am").replacingOccurrences(of: " pm", with: "pm")
        let noonMidnightAdjustedString = convertMidnightAndNoon(in: ampmAdjustedString)
        return noonMidnightAdjustedString
    }
    
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
