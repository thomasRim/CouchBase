//
//  DateFormattingManager.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-10-05.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation

class DateFormattingManager {
    private static let locale = Locale(identifier: "en_US_POSIX")
    private static let gmtTimeZone = TimeZone(secondsFromGMT: 0)
    private static let localTimeZone = TimeZone.autoupdatingCurrent


    static let iso8601DateTimeFormatter:DateFormatter = {
        let iso8601DateTimeFormatter = DateFormatter()
        iso8601DateTimeFormatter.locale = locale
        iso8601DateTimeFormatter.timeZone = gmtTimeZone
        iso8601DateTimeFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
        return iso8601DateTimeFormatter
    }()

    static let estDateTimeFormatter: DateFormatter = {
        let estDateTimeFormatter = DateFormatter()
        estDateTimeFormatter.locale = locale
        estDateTimeFormatter.timeZone = TimeZone(abbreviation: "EST")
        estDateTimeFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
        return estDateTimeFormatter
    }()
}
