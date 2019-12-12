//
//  Dictionary+nilRemoved.swift
//  Scanner
//
//  Created by Vladimir Evdokimov on 2019-03-06.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == Any? {
    public var withNilValuesRemoved: Dictionary<String, Any> {
        var filtered = Dictionary<String, Any>(minimumCapacity: count)
        for (key, value) in self {
            if value != nil {
                filtered[key] = value
            }
        }
        return filtered
    }
}
