//
//  OGAsset.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 24.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

struct OGAsset: OGConvertable {
    // protocol
    var id : String = UUID().uuidString
    var entity: String = "\(OGAsset.self)"

    // entity
    var type: String = ""
    var caption: String = ""
    var data: Data?
    var previewData : Data?
    var createdAt: Date = Date()
    var deviceSerial: String = ""
    var isDeletable: Bool = true

    // relation
    var orderId: String = ""

    func order() -> OGOrder? {
        return OGDatabaseManager.order(for: self)
    }
}
