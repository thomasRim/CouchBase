//
//  OGOrder.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 25.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import CouchbaseLite

enum DeliveryPrefereceType: String, CaseIterable {
    case SHIP
    case PICK_UP_AT_LAB

    static func titles() -> [String] {
        return [ "Ship to Clinic",
                 "Pick up from Lab"
        ]
    }
}

enum ShippingPrefereceType: String, CaseIterable {
    case INDIVIDUALLY
    case WAIT_FOR_ORDERS
    case FLEXIBLE
    case RUSH

    static func titles() -> [String] {
        return [ "Ship Individually",
                 "Wait for X orders, max Y days",
                 "Select Shipping Date"
        ]
    }
}

class OGOrder: NSObject, OGConvertable {
    // protocol
    var id: String = UUID().uuidString
    var entity: String = "\(OGOrder.self)"

    // entity
    var receivedDate: String = Date().iso8601DateTime()
    var submittedAt: String? // ISO date
    var notes: String = ""
    
    var shippingPreferenceType: String = ""
    var deliveryPreferenceType: String = ""
    var numberOfDaysToWait: Int = 0
    var numberOfOrdersToWait: Int = 0
    var preferredShipDate: String? // ISO date
    var rushDays: Int = 0
    var withShoes: Bool = false
    
    // relation
    var patientId: String = ""

    func assets() -> [OGAsset] {
        return OGDatabaseManager.allAssets(for: self)
    }
    
    func patient() -> OGPatient? {
        return OGDatabaseManager.patient(for: self)
    }

    func applyAction(_ action: OGConvertableAction) {
        switch action {
        case .saveUpdate:
            OGDatabaseManager.save(self)
        case .delete:
            OGDatabaseManager.delete(self)
        }
    }
}
