//
//  OGPatient.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 25.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift


struct OGPatient: OGConvertable {
    var id: String = UUID().uuidString
    var entity: String = "\(OGPatient.self)"


    // entity
    var firstName: String?
    var lastName: String?
    var dateOfBirth: Date = Date()
    var weight: Int = 0
    var weightUnit: String = "lbs"
    var gender: String = "other"
    var footTemplateSizeLeft: Float = 0
    var footTemplateSizeRight: Float = 0
    var notes: String = ""

    // relation
    var clinicId: String = ""
    //orders

    func clinic() -> OGClinic? {
        return OGDatabaseManager.clinic(for:self)
    }
}
