//
//  FileNotifications.swift
//  CB_DB
//
//  Created by V.Yevdokymov on 2019-12-12.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let authLoginSuccessful = Notification.Name("kAuthLoginSuccessfulNotification")
    static let authClinicDidChange = Notification.Name("kAuthClinicDidChangeNotification")
    static let authLogoutSuccessful = Notification.Name("kAuthLogoutSuccessfulNotification")
    static let clinicNameDidChange = Notification.Name("kClinicNameDidChangeNotification")
    static let orderDidChange = Notification.Name("kOrderDidChangeNotification")
    
    static let patientNameDidChange = Notification.Name("kPatientNameDidChangeNotification")
    static let orderSubmissionDidStart = Notification.Name("kOrderSubmissionDidStartNotification")
    static let orderSubmissionProgress = Notification.Name("")
    static let orderSubmissionDidFail = Notification.Name("")
    static let orderSubmissionDidSucceed = Notification.Name("kOrderSubmissionDidSucceedNotification")


    
}

let OrderSubmissionProgressPercentageKey = "OrderSubmissionProgressPercentageKey"
