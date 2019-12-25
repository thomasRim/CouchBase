//
//  Data+hex.swift
//  CB_DB
//
//  Created by Vladimir Yevdokimov on 14.12.2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation

extension Data {
    var hexString: String {
        return map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
    }
}
