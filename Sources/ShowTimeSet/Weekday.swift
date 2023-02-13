//
//  Weekday.swift
//  
//
//  Created by Anna Podobrii on 13.02.2023.
//

import Foundation

public enum Weekday: Int {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1
    
    static var weekdayDetailList: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    
    static func oneWeekFromCurrentDate() -> Date {
        let currentDate = Date()
        var currentDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: currentDate)
        currentDateComponents.day = (currentDateComponents.day ?? 0) + 7
        let oneWeekFromCurrentDate = Calendar.current.date(from: currentDateComponents) ?? Date()

        return oneWeekFromCurrentDate
    }
    
    static func weekdayForToday(relativeTo selectedDate: Date) -> Weekday? {
        let oneWeekFromToday = Date.oneWeekFromCurrentDate()
        guard selectedDate < oneWeekFromToday else {
            return nil
        }
        let todayWeekday = Weekday(rawValue: Date().weekDay())
        return todayWeekday
    }
    
    func initial() -> String {
        switch self {
        case .monday:
            return "M"
        case .tuesday:
            return "T"
        case .wednesday:
            return "W"
        case .thursday:
            return "T"
        case .friday:
            return "F"
        case .saturday:
            return "S"
        case .sunday:
            return "S"
        }
    }
    
    func weekdayName() -> String {
        switch self {
        case .monday:
            return "Monday"
        case .tuesday:
            return "Tuesday"
        case .wednesday:
            return "Wednesday"
        case .thursday:
            return "Thursday"
        case .friday:
            return "Friday"
        case .saturday:
            return "Saturday"
        case .sunday:
            return "Sunday"
        }
    }
    
    func weekdayAbbreviation() -> String {
        switch self {
        case .monday:
            return "Mon"
        case .tuesday:
            return "Tue"
        case .wednesday:
            return "Wed"
        case .thursday:
            return "Thu"
        case .friday:
            return "Fri"
        case .saturday:
            return "Sat"
        case .sunday:
            return "Sun"
        }
    }
    
    func soonWeekdays() -> [Weekday] {
        switch self {
        case .monday:
            return [.tuesday, .wednesday]
        case .tuesday:
            return [.wednesday, .thursday]
        case .wednesday:
            return [.thursday, .friday]
        case .thursday:
            return [.friday, .saturday]
        case .friday:
            return [.saturday, .sunday]
        case .saturday:
            return [.sunday, .monday]
        case .sunday:
            return [.monday, .tuesday]
        }
    }
    
    func upcomingWeekdays() -> [Weekday] {
        switch self {
        case .monday:
            return [.tuesday, .wednesday, .thursday, .friday, .saturday, .sunday, .monday]
        case .tuesday:
            return [.wednesday, .thursday, .friday, .saturday, .sunday, .monday, .tuesday]
        case .wednesday:
            return [.thursday, .friday, .saturday, .sunday, .monday, .tuesday, .wednesday]
        case .thursday:
            return [.friday, .saturday, .sunday, .monday, .tuesday, .wednesday, .thursday]
        case .friday:
            return [.saturday, .sunday, .monday, .tuesday, .wednesday, .thursday, .friday]
        case .saturday:
            return [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        case .sunday:
            return [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        }
    }
    
    func daysRelative(to otherWeekday: Weekday) -> Int {
        var relativeDays: Int = 0
        var adjustmentFactor: Int = 0
        
        switch otherWeekday {
        case .monday:
            adjustmentFactor = 0
        case .tuesday:
            adjustmentFactor = 1
        case .wednesday:
            adjustmentFactor = 2
        case .thursday:
            adjustmentFactor = 3
        case .friday:
            adjustmentFactor = 4
        case .saturday:
            adjustmentFactor = 5
        case .sunday:
            adjustmentFactor = 6
        }
        
        switch self {
        case .monday:
            relativeDays = 0 + adjustmentFactor
        case .tuesday:
            relativeDays = -1 + adjustmentFactor
        case .wednesday:
            relativeDays = -2 + adjustmentFactor
        case .thursday:
            relativeDays = -3 + adjustmentFactor
        case .friday:
            relativeDays = -4 + adjustmentFactor
        case .saturday:
            relativeDays = -5 + adjustmentFactor
        case .sunday:
            relativeDays = -6 + adjustmentFactor
        }
        
        return relativeDays
    }
}
