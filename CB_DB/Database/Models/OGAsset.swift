//
//  OGAsset.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 24.11.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import CouchbaseLite

enum DefaultAssetNames: String {
    case leftFoot = "OAssetLF"
    case rightFoot = "OAssetRF"
    case bothFeet = "OAssetBothFeet"
    case shoes = "OAssetShoes"
    case insoles = "OAssetInsoles"
    case replicatePrevious = "OAssetReplicate"
    case photos = "OAssetPhotos"
}

enum AssetScanType: String {
    case ToeUp
    case ToeDown
    case FoamBox
    case PlasterCast
    case BothFeet
    case Shoes
    case Insoles
    case ReplicatedPrevious
}

class OGAsset: NSObject, OGConvertable {
    
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

    var scanType: String = ""
    var scanSide: String = ""
    
    // relation
    var orderId: String = ""

    func order() -> OGOrder? {
        return OGDatabaseManager.order(for: self)
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
