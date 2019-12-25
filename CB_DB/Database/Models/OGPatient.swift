//
//  OGPatient.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 25.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import CouchbaseLite

class OGPatient: OGConvertable {
    
    var id: String = UUID().uuidString
    var entity: String = "\(OGPatient.self)"


    // entity
    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: String = Date().stringWithFormat(.iso8601)
    var weight: Int = 0
    var weightUnit: String = "lbs"
    var gender: String = "other"
    var footTemplateSizeLeft: Float = 0
    var footTemplateSizeRight: Float = 0
    var notes: String = ""

    // relation
    var clinicId: String = ""
    
    func orders() -> [OGOrder] {
        return OGDatabaseManager.allOrders(for: self)
    }

    func clinic() -> OGClinic? {
        return OGDatabaseManager.clinic(for:self)
    }

    //MARK: - Other

    func name() -> String {
        let firstNameString: String = self.firstName
        let lastNameString: String = self.lastName
        return "\(lastNameString), \(firstNameString)"
    }
}
