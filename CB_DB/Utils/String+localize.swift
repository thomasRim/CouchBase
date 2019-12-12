//
//  String+localize.swift
//  Scanner
//
//  Created by Vladimir Yevdokimov on 2/14/19.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation

extension String {
    func localized(_ comment:String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
