//
//  FormLoadable.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-07.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import XLForm

protocol FormLoadable {
    mutating func loadValuesFromForm(_ form: XLFormDescriptor)
}
