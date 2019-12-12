//
//  Date+format.swift
//  Scanner
//
//  Created by Vladimir Evdokimov on 2019-02-21.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation

/**
 *  DateFormats
 */
enum DateFormat:String {
    case MMddyy = "MM/dd/yy"
    case MMMMddyyyy = "MMMM dd, yyyy"
    case MMMMdd = "MMMM dd"
    case MDYHma = "MMM dd, yyyy HH:mm a"
    case Mdyhma = "MM/dd/yy hh:mm a"
    case MM_dd_yyyy = "MM-dd-yyyy"
    case MMddyyyy = "MM/dd/yyyy"
    case mmss = "mm:ss"
    case Hma = "HH:mm a"
    case EEEMMMddyyyy = "EEE, MMM dd, yyyy"
    case EEEEMMMMddyyyy = "EEEE, MMMM dd, yyyy"
    case MMMMddyyyyAtHna = "MMMM dd, yyyy 'at' HH:mm a"
}

extension Date {
    func stringWithFormat(_ format:DateFormat) -> String {
        return self.stringWithFormat(format.rawValue)
    }
    
    func stringWithFormat(_ formatString:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatString
        let str = self
        return dateFormatter.string(from: str)
    }
}

extension String {
    func dateWithFormat(_ formatString:String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatString
        let string = self
        return dateFormatter.date(from: string)
    }
}

extension Data {
    var hexString: String {
        return map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
    }
}


extension Date {
    private static let locale = Locale(identifier: "en_US_POSIX")
    private static let gmtTimeZone = TimeZone(secondsFromGMT: 0)
    private static let localTimeZone = TimeZone.autoupdatingCurrent
    
    func iso8601DateTime() -> String {
        let f = DateFormatter()
        f.locale = Date.locale
        f.timeZone = Date.gmtTimeZone
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return f.string(from: self)
    }
    
    func iso8601LocalDate() -> String {
        let f = DateFormatter()
        f.locale = Date.locale
        f.timeZone = Date.localTimeZone
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
    
    func estDateTime() -> String {
        let f = DateFormatter()
        f.locale = Date.locale
        f.timeZone = TimeZone(abbreviation: "EST")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return f.string(from: self)
    }
}
