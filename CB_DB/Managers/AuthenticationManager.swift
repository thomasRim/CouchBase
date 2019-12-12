//
//  AuthenticationManager.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-03.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation

class AuthenticationManager : NSObject {
    
    static private(set) var currentClinic: OGClinic?
    static var currentPractitioner: OGPractitioner?
    static var currentPatient: OGPatient?
    
    static var authDataSet: Bool {
        get {
            return (self.currentClinic != nil && self.currentPractitioner != nil)
        }
    }
    
    static func authenticate() {
        let clinicName: String = currentClinic?.name ?? ""
        let practitionerName: String = currentPractitioner?.name ?? ""

        NotificationCenter.default.post(name: NSNotification.Name.authLoginSuccessful, object: self)
    }
    
    static func switchClinic(_ clinic: OGClinic?) {
        AuthenticationManager.currentClinic = clinic
        
        NotificationCenter.default.post(name: NSNotification.Name.authClinicDidChange, object: self)
    }
    
    static func logout() {
        AuthenticationManager.currentClinic = nil
        AuthenticationManager.currentPractitioner = nil
        AuthenticationManager.currentPatient = nil
       
        NotificationCenter.default.post(name: Notification.Name.authLogoutSuccessful, object: nil)
    }
}
