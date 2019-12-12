//
//  UIColor+hex.swift
//  CB_DB
//
//  Created by V.Yevdokymov on 2019-12-12.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(with hex: String) {
        let string = hex.replacingOccurrences(of: "#", with: "0x")
        let rgbValue = (string as NSString).intValue
        self.init(_colorLiteralRed:((Float)((rgbValue & 0xFF0000) >> 16))/255.0,
                            green: ((Float)((rgbValue & 0x00FF00) >>  8))/255.0,
                            blue: ((Float)((rgbValue & 0x0000FF) >>  0))/255.0,
                            alpha: 1.0)
    }
}
