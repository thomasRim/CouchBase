//
//  OGPractitioner.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 25.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import CouchbaseLite

class OGPractitioner: OGConvertable {

    var id: String = UUID().uuidString
    var entity: String = "\(OGPractitioner.self)"

    // entity
    var name: String?

    // relation
    func clinics() -> [OGClinic] {
        return OGDatabaseManager.allClinics(for: self)
    }
}
