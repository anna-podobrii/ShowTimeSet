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
}

struct ShowEventTime {
    
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

struct ShowEventTimeList {
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

extension DateInterval {
    func datesInInterval() -> [Date] {
        let calendar = NSCalendar.current
        // start with beginning date
        var date = calendar.startOfDay(for: start)
        
        let numberOfDaysToEndOfInterval = calendar.dateComponents([.day], from: start, to: end)
        
        var dates: [Date] = [date]
        
        guard let numberOfDays = numberOfDaysToEndOfInterval.day else {
            return dates
        }
        if numberOfDays > 0 {
            for _ in 1 ... numberOfDays {
                date = calendar.date(byAdding: Calendar.Component.day, value: 1, to: date)!
                dates.append(date)
            }
        }
        return dates
    }
}
