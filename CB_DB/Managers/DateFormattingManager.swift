//
//  DateFormattingManager.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-10-05.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation

class DateFormattingManager {
    static let sharedManager = DateFormattingManager() // TODO use dispatch_once eventually
    
    // info: http://oleb.net/blog/2011/11/working-with-date-and-time-in-cocoa-part-2/
    var iso8601DateTimeFormatter: DateFormatter!
    var iso8601LocalDateFormatter: DateFormatter!
    var estDateTimeFormatter: DateFormatter!
    
    
    init() {
        let locale = Locale(identifier: "en_US_POSIX")
        let gmtTimeZone = TimeZone(secondsFromGMT: 0)
        let localTimeZone = TimeZone.autoupdatingCurrent
        
        iso8601DateTimeFormatter = DateFormatter()
        iso8601DateTimeFormatter.locale = locale
        iso8601DateTimeFormatter.timeZone = gmtTimeZone
        iso8601DateTimeFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
        
        iso8601LocalDateFormatter = DateFormatter()
        iso8601LocalDateFormatter.locale = locale
        iso8601LocalDateFormatter.timeZone = localTimeZone
        iso8601LocalDateFormatter.dateFormat = "yyyy'-'MM'-'dd"
        
        estDateTimeFormatter = DateFormatter()
        estDateTimeFormatter.locale = locale
        estDateTimeFormatter.timeZone = TimeZone(abbreviation: "EST")
        // HACK: We want GDocs to display EST time, so we pretend it's UTC
        //       This would obviously need to be changed for a real backend...
        estDateTimeFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
//        estDateTimeFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSz"
    }
}
