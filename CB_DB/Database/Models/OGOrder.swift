//
//  OGOrder.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 25.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

struct OGOrder: OGConvertable {
    // protocol
    var id: String = UUID().uuidString
    var entity: String = "\(OGOrder.self)"

    // entity
    var orderReceivedDate: Date = Date()
    var orderMustShipDate: Date?
    var orderRush: String = RushValue.none.rawValue
    var submittedAt: Date?
    var notes: String = ""

    // relation
    var patientId: String = ""
    //assets

    func patient() -> OGPatient? {
        return OGDatabaseManager.patient(for: self)
    }
    
    // other
    enum RushValue: String, CaseIterable {
        case none = "NONE"
        case day1 = "1 Day"
        case day2 = "2 Day"
        case day3 = "3 Day"
        case day4 = "4 Day"
    }

}
