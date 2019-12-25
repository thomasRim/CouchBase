//
//  Date+workDays.swift
//  CB_DB
//
//  Created by Vladimir Yevdokimov on 14.12.2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation

extension Date {
    func isWorkingDay() -> Bool {
        let weekWorkDays = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let string = dateFormatter.string(from: self)
        return weekWorkDays.contains(string)
    }

    func workingDaysFromToday() -> Int {
        let todayStartDateTimeInterval = Calendar.startOfDay(Calendar.current)(for: Date()).timeIntervalSince1970
        let currentStartDateTimeInterval = Calendar.startOfDay(Calendar.current)(for: self).timeIntervalSince1970

        let secsInDay:Double = 24*60*60
        let days = Int((currentStartDateTimeInterval - todayStartDateTimeInterval) / secsInDay)
        if days == 0 { return 0 }

        var workingDays = 0
        for  day in 1...abs(days) {
            let weekday = Date(timeIntervalSince1970: Date().timeIntervalSince1970 +  Double(days > 0 ? day : (day * -1)) * secsInDay )
            if weekday.isWorkingDay() { workingDays += 1}
        }

        return workingDays
    }
}
