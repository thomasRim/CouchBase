//
//  Order+SubmissionHelpers.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-10-02.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation

extension OGOrder {

    func submissionDictForSubmittedAt(_ submittedAt: Date, archiveFilename: String) -> [String: Any] {
        var assetDicts = [[String: Any]]()
        
        var i: UInt = 1
        for asset in self.assets() {
            if asset.data != nil {
                assetDicts.append(self.submissionDictForAsset(asset, filename: asset.friendlyFilenameWithIndex(i)!))
                i += 1
            }
        }


        var orderDict: [String: Any] = [
            "uniqueId": self.id,
            "appVersion": AppInfo.sharedInfo.versionString as AnyObject,
            "submittedAt": DateFormattingManager.sharedManager.estDateTimeFormatter.string(from: submittedAt),
            "assets": assetDicts,
            "shippingPreferenceType": self.shippingPreferenceType,
            "deliveryPreferenceType":self.deliveryPreferenceType,
            "additionalNotes": self.notes
        ]

        switch self.deliveryPreferenceType {
        case ShippingPrefereceType.WAIT_FOR_ORDERS.rawValue:
            orderDict["numberOfDaysToWait"] = self.numberOfDaysToWait
            orderDict["numberOfOrdersToWait"] = self.numberOfOrdersToWait;
        case ShippingPrefereceType.FLEXIBLE.rawValue:
            orderDict["preferredShipDate"] = self.preferredShipDate ?? ""
        case ShippingPrefereceType.RUSH.rawValue:
            orderDict["rushDays"] = "\(self.rushDays)"
        default: break
        }

        // clinic
        var submittingClinic = Dictionary<String,Any?>()
        submittingClinic["practitionerName"] = AuthenticationManager.currentPractitioner!.name

        if let clinic = self.patient()?.clinic() {
            var submittingClinic = Dictionary<String,Any?>()
            submittingClinic["name"] = clinic.name
            if let email = clinic.contactEmail { submittingClinic["contactEmail"] = email }
            if let phoneNumber = clinic.phoneNumber { submittingClinic["phoneNumber"] = phoneNumber }
            
            if let address = clinic.address { submittingClinic["address"] = address }
            if let city = clinic.city { submittingClinic["city"] = city }
            if let province = clinic.province { submittingClinic["province"] = province.localized() }
            if let postalCode = clinic.postalCode { submittingClinic["postalCode"] = postalCode }
        }

        let patient = self.patient()
        let patientData: Dictionary<String,Any?> = [
            "firstName": patient?.firstName ?? "",
            "lastName": patient?.lastName ?? "",
            "dateOfBirth": DateFormattingManager.sharedManager.iso8601LocalDateFormatter?.string(from: Date(timeIntervalSince1970: patient?.dateOfBirth ?? 0)),
            "weight": patient?.weight ?? 0,
            "weightUnit": patient?.weightUnit ?? "lbs",
            "gender": patient?.gender ?? "",
            "footTemplateSizeLeft": patient?.footTemplateSizeLeft ?? 0,
            "footTemplateSizeRight": patient?.footTemplateSizeRight ?? 0,
            "notes": patient?.notes ?? ""
        ]
        
        
        let returnDict: Dictionary<String,Any?> =  [
            "archiveFilename": archiveFilename
            , "order": orderDict
            , "patient": patientData
            , "submittingClinic": submittingClinic
        ]

//        CLSLogv("Order: %@", getVaList([self.debugDescription]))
//        CLSLogv("Clinic: %@", getVaList([clinic.debugDescription]))
//        CLSLogv("Patient: %@", getVaList([patient.debugDescription]))
//        CLSLogv("Submission dict: %@", getVaList([returnDict]))

        let refinedData = returnDict//.withNilValuesRemoved
        return refinedData
    }
    
    func submissionDictForAsset(_ asset: OGAsset, filename: String) -> [String: Any] {
        if asset.type == "photo" {
            return [ "type": asset.type,
                     "caption": asset.caption,
                     "filename": filename,
                     "createdAt": DateFormattingManager.sharedManager.iso8601DateTimeFormatter.string(from: asset.createdAt)
            ]
        } else {
            let scanName = asset.caption
            let scanType = asset.scanType
            let scanSide: String = asset.scanSide
            let scanRequiresRotation: Bool = (asset.scanType == AssetScanType.ToeDown.rawValue)
            let scanRequiresAlignment: Bool = (asset.scanType == AssetScanType.FoamBox.rawValue) || (asset.scanType == AssetScanType.PlasterCast.rawValue)
            let scanThumbUp = (asset.scanType == AssetScanType.ToeDown.rawValue) || (asset.scanType == AssetScanType.ToeUp.rawValue) ? asset.scanSide : ""
            
            return ["type": asset.type,
                    "caption": scanName,

                    "scanName": scanName,
                    "scanType": scanType,
                    "scanSide": scanSide,
                    "scanThumbUp": scanThumbUp ,
                    "scanRequiresRotation": scanRequiresRotation,
                    "scanRequiresAlignment": scanRequiresAlignment,

                    "filename": filename,
                    "deviceSerial": asset.deviceSerial,
                    "createdAt": DateFormattingManager.sharedManager.iso8601DateTimeFormatter.string(from: asset.createdAt) ]
        }
    }
}
