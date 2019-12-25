//
//  OGClinic.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 24.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import CouchbaseLite

class OGClinic: OGConvertable {
    // protocol
    var id: String = UUID().uuidString
    var entity: String = "\(OGClinic.self)"

    // entity
    var name: String = ""
    var address: String?
    var city: String?
    var postalCode: String?
    var province: String?
    var contactEmail: String?
    var phoneNumber: String?
    
    // relation
    var practitionerId: String = ""

    func patients() -> [OGPatient] {
        return OGDatabaseManager.allPatients(for: self)
    }

    func practitioner() -> OGPractitioner? {
        return OGDatabaseManager.practitioner(for: self)
    }
}
