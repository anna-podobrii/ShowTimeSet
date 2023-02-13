//
// Date.swift
//  
//
//  Created by Anna Podobrii on 13.02.2023.
//

import Foundation

let soonDaysForShowsAndEvent: Int = 2

extension Date {
    static func currentDate(matches date:Date) -> Bool {
        let currentDate = Date()
        let currentDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: currentDate)
        let matchDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date)
        
        return currentDateComponents.day == matchDateComponents.day &&
        currentDateComponents.month == matchDateComponents.month &&
        currentDateComponents.year == matchDateComponents.year
    }

    func matches(date:Date) -> Bool {
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        let matchDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date)
        
        return dateComponents.day == matchDateComponents.day &&
        dateComponents.month == matchDateComponents.month &&
        dateComponents.year == matchDateComponents.year
    }

    func isBefore(_ comparisonDate: Date) -> Bool {
        var comparisonDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: comparisonDate)
        comparisonDateComponents.hour = 0
        comparisonDateComponents.minute = 0
        comparisonDateComponents.second = 0
        var matchDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        matchDateComponents.hour = 0
        matchDateComponents.minute = 0
        matchDateComponents.second = 0

        let calendar = Calendar.current
        guard let selfComparisonDate = calendar.date(from: matchDateComponents), let normalizedComparisonDate = calendar.date(from: comparisonDateComponents) else {
            return false
        }
        let dateComparison = selfComparisonDate.compare(normalizedComparisonDate)
        let comparison = dateComparison == .orderedAscending
        return comparison
    }
    
    static func getDates(for selectedDate: Date, forLastNDays nDays: Int) -> [Date] {
        let cal = NSCalendar.current
        // start with today
        var date = cal.startOfDay(for: selectedDate.prevDate())
        
        var arrDates = [Date]()
        
        for _ in 1 ... nDays {
            // move back in time by one day:
            date = cal.date(byAdding: Calendar.Component.day, value: 1, to: date)!
            arrDates.append(date)
        }
        return arrDates
    }

    static func weekDay(for selectedDate:Date) -> Int {
        let selectedDateComponents = Calendar.current.dateComponents([.weekday], from: selectedDate)
        let weekday = selectedDateComponents.weekday ?? 1
        return weekday
    }
        
    static func oneWeekFromCurrentDate(matches date:Date) -> Bool {
        let currentDate = Date()
        var currentDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: currentDate)
        currentDateComponents.day = (currentDateComponents.day ?? 0) + 7
        let oneWeekFromCurrentDate = Calendar.current.date(from: currentDateComponents) ?? Date()
        
        let oneWeekFromCurrentDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: oneWeekFromCurrentDate)
        let matchDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date)
        
        return oneWeekFromCurrentDateComponents.day == matchDateComponents.day &&
            oneWeekFromCurrentDateComponents.month == matchDateComponents.month &&
            oneWeekFromCurrentDateComponents.year == matchDateComponents.year
    }

    static func oneWeekFromCurrentDate() -> Date {
        let currentDate = Date()
        var currentDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: currentDate)
        currentDateComponents.day = (currentDateComponents.day ?? 0) + 7
        let oneWeekFromCurrentDate = Calendar.current.date(from: currentDateComponents) ?? Date()

        return oneWeekFromCurrentDate
    }

    static func oneYearFromCurrentDate() -> Date {
        let currentDate = Date()
        var currentDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: currentDate)
        currentDateComponents.year = (currentDateComponents.year ?? 2020) + 1
        let oneYearFromCurrentDate = Calendar.current.date(from: currentDateComponents) ?? Date()
        return oneYearFromCurrentDate
    }
    
    public var endOfDay: Date? {
        var currentComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        currentComponents.timeZone = TimeZone.current.isDaylightSavingTime(for: self) ? TimeZone.init(abbreviation: "PDT") : TimeZone.init(abbreviation: "PST")
        let dateForEndOfDay = Calendar.current.date(from: currentComponents) ?? self
        var components = DateComponents()
        components.day = 1
        components.second = -1
        let date = Calendar.current.date(byAdding: components, to: dateForEndOfDay)
        return date
    }

    func dateWithTime(hour: Int, minute: Int) -> Date {
        var dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        dateComponents.hour = hour
        dateComponents.minute = minute
        return Calendar.current.date(from: dateComponents) ?? self
    }

    func nextDate() -> Date {
        var afterDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        afterDateComponents.day = (afterDateComponents.day ?? 0) + 1
        let nextDate = Calendar.current.date(from: afterDateComponents) ?? Date()
        return nextDate
    }

    func dateByAdding(days numberOfDays: Int) -> Date {
        var afterDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        afterDateComponents.day = (afterDateComponents.day ?? 0) + numberOfDays
        let nextDate = Calendar.current.date(from: afterDateComponents) ?? Date()
        return nextDate
    }
    
    func prevDate() -> Date {
        var beforeDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        beforeDateComponents.day = (beforeDateComponents.day ?? 0) - 1
        let prevDate = Calendar.current.date(from: beforeDateComponents) ?? Date()
        return prevDate
    }
    
    func weekDay(for selectedDate:Date) -> Int {
        let selectedDateComponents = Calendar.current.dateComponents([.weekday], from: selectedDate)
        return selectedDateComponents.weekday ?? 1
    }

    func weekDay() -> Int {
        let dateComponents = Calendar.current.dateComponents([.weekday], from: self)
        return dateComponents.weekday ?? 1
    }

    func soonDateInterval() -> DateInterval {
        var afterDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        afterDateComponents.day = (afterDateComponents.day ?? 0) + soonDaysForShowsAndEvent
        afterDateComponents.hour = 23
        afterDateComponents.minute = 59
        afterDateComponents.second = 59
        if let timeZone = TimeZone(identifier: "US/Pacific") {
            afterDateComponents.timeZone = timeZone
        }
 
        if let endDate = Calendar.current.date(from: afterDateComponents) {
            return DateInterval(start: self, end: endDate)
        }
        let twoDays: Double = 23.0 * 60.0 * 60.0 * 2 + 60.0 * 59.0 + 59.0
        return DateInterval(start: self, duration: twoDays)
    }
    
    static func dateFrom(month: Int, day: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.month = month
        components.day = day
        components.year = year
        return Calendar.current.date(from: components)
    }
    
    static func getAllDaysOfTheCurrentWeek(currentDate: Date) -> [Date] {
        var calendar = Calendar.autoupdatingCurrent
        calendar.firstWeekday = 2 // Start on Monday (or 1 for Sunday)
        let today = calendar.startOfDay(for: currentDate)
        var week = [Date]()
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) {
            for i in 0...6 {
                if let day = calendar.date(byAdding: .day, value: i, to: weekInterval.start) {
                    week += [day]
                }
            }
        }
        return week
    }
    
    func relativeDate(for otherWeekday:Weekday) -> Date {
        guard let weekday = Weekday(rawValue: self.weekDay()) else { return self }
        let relativeDays = weekday.daysRelative(to: otherWeekday)
        
        return self.dateByAdding(days: relativeDays)
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

