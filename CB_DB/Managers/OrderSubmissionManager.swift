//
//  OrderSubmissionManager.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-10-09.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import AWSS3
import SSZipArchive
import Alamofire

class OrderSubmissionManager: NSObject { // TODO get rid of this inheritance when possible
    static let sharedManager = OrderSubmissionManager() // TODO use dispatch_once eventually
    
    func submitOrder(_ order: OGOrder) {
        self.notifyStart()

        var success: Bool
        let tmpDirURL = self.tmpDirURLForOrder(order)

        do {
            try FileManager.default.createDirectory(at: tmpDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Error creating temp dir for order: %@ %@", error, error.userInfo)
            self.notifyFailure()
            return
        }

        let clinicNameForFilename: String = order.patient()?.clinic()?.name.sanitizedFilename() ?? ""
        let patientLastNameForFilename: String = order.patient()?.lastName.sanitizedFilename() ?? ""
        let patientFirstNameForFilename: String = order.patient()?.firstName.sanitizedFilename() ?? ""
        let uniqID: String = order.id
        let archiveBaseFilename = "\(clinicNameForFilename)_\(patientLastNameForFilename)-\(patientFirstNameForFilename)_\(uniqID).zip"
        
        // save JSON manifest
        let submittedAt = Date()
        let submissionDict = order.submissionDictForSubmittedAt(submittedAt, archiveFilename: archiveBaseFilename)
        let manifestURL = tmpDirURL.appendingPathComponent("manifest.json")
        
        var manifestJsonData: Data
        do {
            try manifestJsonData = JSONSerialization.data(withJSONObject: submissionDict, options: JSONSerialization.WritingOptions.prettyPrinted)
        } catch let error as NSError {
            NSLog("Error creating JSON manifest: %@ %@", error, error.userInfo)
            self.notifyFailure()
            return
        }

        success = (try? manifestJsonData.write(to: manifestURL, options: [.atomic])) != nil
        if !success {
            NSLog("Error writing JSON manifest")
            self.notifyFailure()
            return
        }
        
        // save all assets with data
        var i: UInt = 1
        for asset in order.assets() {
            if asset.data != nil {
                let filename = asset.friendlyFilenameWithIndex(i)!
                let assetFileURL = tmpDirURL.appendingPathComponent(filename)
                
                do {
                    try asset.data?.write(to: assetFileURL, options: NSData.WritingOptions.atomicWrite)
                } catch let error as NSError {
                    NSLog("Error writing asset to file: %@ %@", error, error.userInfo)
                    self.notifyFailure()
                    return
                }
                
                i += 1
            }
        }

        // zip everything up
        let archiveURL = URL(fileURLWithPath: NSTemporaryDirectory() + archiveBaseFilename)
        success = SSZipArchive.createZipFile(atPath: archiveURL.path, withContentsOfDirectory: tmpDirURL.path)
        if !success {
            NSLog("Error creating order archive!")
            self.notifyFailure()
            return
        }
        
        let isS3Canadian = awsCognitoIdentityPoolId.starts(with: "ca-")
        let regionCogito: AWSRegionType = isS3Canadian ? AWSRegionType.CACentral1 : AWSRegionType.EUWest1
        let regionBucket: AWSRegionType = isS3Canadian ? AWSRegionType.CACentral1 : AWSRegionType.USEast1
        
        // submit!
        // http://docs.aws.amazon.com/mobile/sdkforios/developerguide/s3transfermanager.html
        let credentialsProvider: AWSCognitoCredentialsProvider = AWSCognitoCredentialsProvider(regionType: regionCogito, // credentials are in this region
//            endpoint:(AWSEndpoint *)endpoint
                                                                            identityPoolId: awsCognitoIdentityPoolId)
        let configuration: AWSServiceConfiguration = AWSServiceConfiguration(region: regionBucket, // buckets are in this region
                                                                credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        let transferManager: AWSS3TransferManager = AWSS3TransferManager.default()
        let uploadRequest: AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
        var archiveFilenameWithPath = archiveBaseFilename
        if awsBucketFolder != "" {
            archiveFilenameWithPath = awsBucketFolder + "/" + archiveFilenameWithPath
        }
        
        uploadRequest.bucket = awsBucketName
        uploadRequest.key = archiveFilenameWithPath
        uploadRequest.body = archiveURL
        
        uploadRequest.uploadProgress = {(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
            let progress: Float = (Float(totalBytesSent) / (Float(totalBytesExpectedToSend) * Float(1.0)))
            NSLog("%f%% Uploaded", progress * 100)
            self.notifyProgress(progress)
        }
        transferManager.upload(uploadRequest).continueWith(executor: AWSExecutor.mainThread()) { (task: AWSTask!) -> Any? in
            if (task.error != nil) {
                if task.error!._domain == AWSS3TransferManagerErrorDomain {
                    switch task.error!._code {
                    case AWSS3TransferManagerErrorType.cancelled.rawValue: break
                    case AWSS3TransferManagerErrorType.paused.rawValue: break
                    default:
                        // HACK: swift 2.3 workaround (see:  https://bugs.swift.org/browse/SR-1478)
                        NSLog("Error uploading file: %@ %@", task.error! as NSObject, task.error!.localizedDescription as NSObject)
                        self.notifyFailure()
                    }
                }
                else {
                    // HACK: swift 2.3 workaround (see:  https://bugs.swift.org/browse/SR-1478)
                    NSLog("Error uploading file: %@ %@", task.error! as NSObject, task.error!.localizedDescription as NSObject)
                    self.notifyFailure()
                }
            }
            if (task.result != nil) {
                NSLog("Upload successful!")
                NSLog("archiveURL = \(archiveURL)")
                
                // clean up temp dir, but don't care about failure (OS will take care of it at some point anyways)
                do {
                    try FileManager.default.removeItem(at: tmpDirURL)
                    try FileManager.default.removeItem(at: archiveURL)
                } catch _ as NSError {}
                
                
                order.submittedAt = submittedAt.stringWithFormat(DateFormat.iso8601)
                OGDatabaseManager.save(order)
                
                self.notifySuccess()
                
            }
            return nil
        }
    }
    
    func submitOrderInBackground(_ order: OGOrder) {
        self.submitOrder(order)
    }

    
    // MARK: - Privates
    
    func tmpDirURLForOrder(_ order: OGOrder) -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(order.id)
    }
    
    func notifyStart() {
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: NSNotification.Name.orderSubmissionDidStart, object: nil, userInfo: nil)
        })
    }
    
    func notifyProgress(_ progress: Float) {
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: NSNotification.Name.orderSubmissionProgress,
                object: nil, userInfo: [OrderSubmissionProgressPercentageKey: progress])
        })
    }
    
    func notifyFailure() {
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: NSNotification.Name.orderSubmissionDidFail, object: nil, userInfo: nil)
        })
    }
    
    func notifySuccess() {
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: NSNotification.Name.orderSubmissionDidSucceed, object: nil, userInfo: nil)
        })
    }
    
}
