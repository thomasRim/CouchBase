//
//  Enum_String+localized.swift
//  Scanner
//
//  Created by Vladimir Evdokimov on 2019-03-11.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation

extension RawRepresentable where RawValue == String {
    var localized: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}
