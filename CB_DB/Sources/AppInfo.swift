//
//  AppInfo.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-11-26.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation

class AppInfo {
    
    static let sharedInfo = AppInfo() // TODO use dispatch_once eventually
    
    var _versionString: String?
    var versionString: String {
        get {
            if _versionString == nil {
                let infoDict = Bundle.main.infoDictionary!
                let bundleName = infoDict[kCFBundleNameKey as String]!
                let version = infoDict["CFBundleShortVersionString"]!
                let build = infoDict[kCFBundleVersionKey as String]!
                
                #if BETA
                    _versionString = "\(bundleName)-Beta v\(version) (\(build))"
                #else
                    _versionString = "\(bundleName) v\(version) (\(build))"
                #endif
            }
            
            return _versionString!
        }
    }
    
}
