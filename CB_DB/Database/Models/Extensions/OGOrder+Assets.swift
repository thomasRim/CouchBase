//
//  Order.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-02.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation

extension OGOrder {
    
    // MARK: - Publics
    
    func reset() {
        self.restoreAssetsToDefault()
        self.notes = ""
    }
   
    func restoreAssetsToDefault() {
        self.removeAllAssets()
        self.createDefaultAssets()
    }

    static let defaultAssetsCaptions = [DefaultAssetNames.leftFoot.localized,
                                 DefaultAssetNames.rightFoot.localized,
                                 DefaultAssetNames.bothFeet.localized,

                                 DefaultAssetNames.insoles.localized,
                                 DefaultAssetNames.shoes.localized,
                                 DefaultAssetNames.replicatePrevious.localized,
    ]
    func createDefaultAssets() {
        for i in 0 ..< OGOrder.defaultAssetsCaptions.count {
            
            let asset: OGAsset = OGAsset()
            asset.caption = OGOrder.defaultAssetsCaptions[i]
            asset.type = "scan"
            asset.isDeletable = false
            asset.createdAt = Date()

            switch asset.caption {
            case DefaultAssetNames.leftFoot.localized:
                asset.scanSide = "Left"
                asset.scanType = ""
            case DefaultAssetNames.rightFoot.localized:
                asset.scanSide = "Right"
                asset.scanType = ""
            case DefaultAssetNames.bothFeet.localized:
                asset.scanSide = ""
                asset.scanType = AssetScanType.BothFeet.rawValue
            case DefaultAssetNames.insoles.localized:
                asset.scanSide = ""
                asset.scanType = AssetScanType.Insoles.rawValue
            case DefaultAssetNames.shoes.localized:
                asset.scanSide = ""
                asset.scanType = AssetScanType.Shoes.rawValue
            case DefaultAssetNames.replicatePrevious.localized:
                asset.scanSide = ""
                asset.scanType = AssetScanType.ReplicatedPrevious.rawValue
            default: break
            }

            asset.orderId = self.id
            OGDatabaseManager.save(asset)
        }
    }
    
    func updateDefaultAssetsIfNeeded(){
        for i in 0 ..< OGOrder.defaultAssetsCaptions.count {
            // check each type if present.
            let captionNew = OGOrder.defaultAssetsCaptions[i]
            
            let a: OGAsset? = getAsset(byCaption: captionNew)
            
            if a == nil {
                let asset = OGAsset()
                asset.caption = captionNew
                asset.type = "scan"
                asset.isDeletable = false
                asset.createdAt = Date()

                switch asset.caption {
                case DefaultAssetNames.leftFoot.localized:
                    asset.scanSide = "Left"
                    asset.scanType = ""
                case DefaultAssetNames.rightFoot.localized:
                    asset.scanSide = "Right"
                    asset.scanType = ""
                case DefaultAssetNames.bothFeet.localized:
                    asset.scanSide = ""
                    asset.scanType = AssetScanType.BothFeet.rawValue
                case DefaultAssetNames.insoles.localized:
                    asset.scanSide = ""
                    asset.scanType = AssetScanType.Insoles.rawValue
                case DefaultAssetNames.shoes.localized:
                    asset.scanSide = ""
                    asset.scanType = AssetScanType.Shoes.rawValue
                case DefaultAssetNames.replicatePrevious.localized:
                    asset.scanSide = ""
                    asset.scanType = AssetScanType.ReplicatedPrevious.rawValue
                default: break
                }

                asset.orderId = self.id
                OGDatabaseManager.save(asset)
            } else {
                // Rename caption if needed.
                if a!.caption == "Both feet (weight-bearing)" {
                   a!.caption = "Both feet"
                }
            }
        }
    }
    
    func getAsset(byCaption caption: String) -> OGAsset? {
        print("search caption = '\(caption)'")
        for asset in self.assets() {
            if asset.type != "scan" {
                continue
            }

            print("asset caption \(asset.caption)")

            switch asset.caption {
            case DefaultAssetNames.leftFoot.localized,
                 DefaultAssetNames.rightFoot.localized,
                 DefaultAssetNames.bothFeet.localized,
                 DefaultAssetNames.insoles.localized,
                 DefaultAssetNames.shoes.localized,
                 DefaultAssetNames.replicatePrevious.localized:
                return asset
            default:
                return nil
            }
        }
        return nil
    }
    
    func duplicateFrom(order: OGOrder) {
        self.receivedDate = order.receivedDate
        self.notes = order.notes

        self.shippingPreferenceType = order.shippingPreferenceType
        self.deliveryPreferenceType = order.deliveryPreferenceType
        self.numberOfDaysToWait = order.numberOfDaysToWait
        self.numberOfOrdersToWait = order.numberOfOrdersToWait
        self.preferredShipDate = order.preferredShipDate
        self.rushDays = order.rushDays
        self.patientId = order.patientId

        self.removeAllAssets()

        // apply new assets
        for asset in order.assets() {
            let newAsset = OGAsset()

            newAsset.type = asset.type
            newAsset.caption = asset.caption
            newAsset.data = asset.data
            newAsset.previewData = asset.previewData
            newAsset.createdAt = asset.createdAt
            newAsset.deviceSerial = asset.deviceSerial
            newAsset.isDeletable = asset.isDeletable
            newAsset.scanType = asset.scanType
            newAsset.scanSide = asset.scanSide

            newAsset.orderId = self.id
            OGDatabaseManager.save(newAsset)
        }
    }

    func addNew3DAssetWithData(_ data: Data, previewData: Data, caption: String, deviceSerial: String) {
        let asset = OGAsset()
        asset.caption = caption
        asset.type = "scan"
        asset.isDeletable = true
        asset.data = data
        asset.previewData = previewData
        asset.deviceSerial = deviceSerial
        asset.createdAt = Date()
        asset.orderId = self.id
        OGDatabaseManager.save(asset)
    }
    
    func addNewPhotoAssetWithPhotoData(_ data: Data, caption: String) {
        let asset = OGAsset()
        asset.caption = caption
        asset.type = "photo"
        asset.isDeletable = true
        asset.setPhotoData(data)
        asset.createdAt = Date()
        asset.orderId = self.id
        OGDatabaseManager.save(asset)
    }
    
    @discardableResult
    func addNew3DAssetWithDataPath(_ dataPath: String, previewDataPath: String, caption: String, deviceSerial: String) -> Bool {
        let asset = OGAsset()
        asset.caption = caption
        asset.type = "scan"
        asset.isDeletable = true
        asset.deviceSerial = deviceSerial
        asset.createdAt = Date()

        asset.orderId = self.id
        asset.changeDataWithPath(dataPath, previewDataPath: previewDataPath)
        OGDatabaseManager.save(asset)

        return true
    }
    
    // MARK: - Privates
    
    func removeAllAssets() {
        for asset in self.assets() {
            OGDatabaseManager.delete(asset)
        }
    }

}
