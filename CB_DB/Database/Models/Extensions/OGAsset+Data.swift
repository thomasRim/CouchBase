//
//  Asset.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-02.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import UIKit
import SSZipArchive

extension OGAsset {
 
    // MARK: - Publics
    
    func changeCaption(_ newCaption: String) {
        if self.caption != newCaption {
            self.caption = newCaption
        }
    }
    
    func changePhotoData(_ assetData: Data) {
        self.setPhotoData(assetData)
    }
    
    func setPhotoData(_ photoData: Data) {
        self.data = photoData
        self.previewData = photoData
    }
    
    func changeData(_ data: Data?, previewData: Data?) {
        self.data = data
        self.previewData = previewData
    }
    
    @discardableResult
    func changeDataWithPath(_ dataPath: String, previewDataPath: String) -> Bool {
        self.cleanupUnzippedAsset()
        
        let assetData: Data?
        do {
            assetData = try Data(contentsOf: URL(fileURLWithPath: dataPath), options: NSData.ReadingOptions.init(rawValue: 0))
        } catch let error as NSError {
            NSLog("Error loading asset data from file: %@ %@", error, error.userInfo)
            return false
        }
        
        let assetPreviewData: Data?
        do {
            assetPreviewData = try Data(contentsOf: URL(fileURLWithPath: previewDataPath), options: NSData.ReadingOptions.init(rawValue: 0))
        } catch let error as NSError {
            NSLog("Error loading asset preview data from file: %@ %@", error, error.userInfo)
            return false
        }
        
        self.data = assetData
        self.previewData = assetPreviewData
        let unzippedArchiveURL: URL = self.unzipAsset()!
        let modelURL: URL = unzippedArchiveURL.appendingPathComponent("Model.obj")
        
        let modelData: Data?
        do {
            modelData = try Data(contentsOf: URL(fileURLWithPath: modelURL.path), options: NSData.ReadingOptions.init(rawValue: 0))
        } catch let error as NSError {
            NSLog("Error loading asset model data from file: %@ %@", error, error.userInfo)
            return false
        }
        
//        let translatedModelData: Data?
//        do {
//            translatedModelData = ObjFileEditor.translateToAlignCenterObject(with: modelData)
//            try translatedModelData!.write(to: modelURL, options: NSData.WritingOptions.init(rawValue: 0))
//        } catch let error as NSError {
//            NSLog("Error writing translated asset model data to file: %@ %@", error, error.userInfo)
//            return false
//        }

        if !self.renameFilesWithBasename("Model", inUnzippedArchiveAtURL:unzippedArchiveURL) {
            NSLog("Error renaming files")
            return false
        }
        
        let translatedArchiveURL: URL = unzippedArchiveURL.deletingLastPathComponent().appendingPathComponent("archive.zip")
        
        if !self.zipContentsOfDirectoryAtURL(unzippedArchiveURL, toFileAtURL:translatedArchiveURL, andAssignDataTo:self) {
            NSLog("Error zipping translated model")
            return false
        }
        
        self.cleanupUnzippedAsset()
        
        return true
    }
    
    func isDefaultAsset() -> Bool {
        return !self.isDeletable
    }
    func placeholderImage() -> UIImage? {
        if self.isDefaultAsset() {
            switch self.caption {
            case DefaultAssetNames.leftFoot.localized:
                return UIImage(named: "scans-foot-left")
            case DefaultAssetNames.rightFoot.localized:
                return UIImage(named: "scans-foot-right")
            case DefaultAssetNames.bothFeet.localized:
                return UIImage(named: "scans-feet-both")
            case DefaultAssetNames.insoles.localized:
                return UIImage(named: "scans-insole")
            case DefaultAssetNames.shoes.localized:
                return UIImage(named: "scans-shoe")
            case DefaultAssetNames.replicatePrevious.localized:
                return UIImage(named: "scans-previous")
            case DefaultAssetNames.photos.localized:
                return UIImage(named: "scans-camera")
            default: break
            }
        }
        return nil
    }
    
    func unzipAsset() -> URL? {
        assert(self.data != nil, "trying to unzip empty data")
        let tmpDirURL: URL = self.tmpDirURL()
        
        do {
            try FileManager.default.createDirectory(at: tmpDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Error creating temp dir for asset: %@ %@", error, error.userInfo)
            return nil
        }
        
        let archiveURL: URL = tmpDirURL.appendingPathComponent("archive.zip")
        
        do {
            try self.data?.write(to: archiveURL, options: NSData.WritingOptions.atomic)
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
        var success: Bool
        do {
            try self.data?.write(to: archiveURL, options: NSData.WritingOptions.atomic)
        } catch {
//            print(error.localizedDescription)
        }
        
        let unzippedArchiveURL: URL = tmpDirURL.appendingPathComponent("contents")
        success = SSZipArchive.unzipFile(atPath: archiveURL.path, toDestination: unzippedArchiveURL.path)
        if !success {
            NSLog("Error unzipping archive")
            return nil
        }
        
        return unzippedArchiveURL
    }
    
    func cleanupUnzippedAsset() {
        do {
            try FileManager.default.removeItem(at: self.tmpDirURL())
        } catch _ {}
    }
    
    func friendlyFilenameBasenameWithCaption(_ withCaption: Bool) -> String {
        let clinicName: String = order()?.patient()?.clinic()?.name.sanitizedFilename() ?? ""
        let patientLastName: String = order()?.patient()?.lastName.sanitizedFilename() ?? ""
        let patientFirstName: String = order()?.patient()?.firstName.sanitizedFilename() ?? ""
        let uniqueID: String = order()?.id ?? ""
        
        var basename: String = "\(clinicName)_\(patientLastName)-\(patientFirstName)_\(uniqueID)"
        if withCaption {
            let captionString: String = caption.sanitizedFilename()
            basename = "\(basename)_\(captionString)"
        }
        return basename
    }
    
    func friendlyFilenameWithIndex(_ index: UInt) -> String? {
        let filenameBasename: String = friendlyFilenameBasenameWithCaption(false)
        var captionString: String = caption.sanitizedFilename()
        if type == "scan" && !self.isDeletable {
            captionString = caption.sanitizedFilename()
        }
        let basename: String = "\(filenameBasename)_\(index)_\(captionString)"
        if type == "photo" {
            return basename + ".jpg"
        }
        else {
            if type == "scan" {
                return basename + ".zip"
            }
            else {
                return nil
            }
        }
    }

    func renameFilesWithBasename(_ basename: String, inUnzippedArchiveAtURL unzippedArchiveURL: URL) -> Bool {
        let modelURL: URL = unzippedArchiveURL.appendingPathComponent("\(basename).obj")
        let textureURL: URL = unzippedArchiveURL.appendingPathComponent("\(basename).jpg")
        let mtlURL: URL = unzippedArchiveURL.appendingPathComponent("\(basename).mtl")
        
        let fileManager: FileManager = FileManager.default
        let friendlyFilenameBasenameWithCaption: String = self.friendlyFilenameBasenameWithCaption(true)
        
        do {
            try fileManager.moveItem(at: modelURL, to: unzippedArchiveURL.appendingPathComponent(friendlyFilenameBasenameWithCaption + ".obj"))
        } catch let error as NSError {
            NSLog("Error renaming OBJ file: %@ %@", error, error.userInfo)
            return false
        }
        
        if fileManager.fileExists(atPath: textureURL.path) {
            do {
                try fileManager.moveItem(at: textureURL, to: unzippedArchiveURL.appendingPathComponent(friendlyFilenameBasenameWithCaption + ".jpg"))
            } catch let error as NSError {
                NSLog("Error renaming JPG file: %@ %@", error, error.userInfo)
                return false
            }
        }
        
        if fileManager.fileExists(atPath: mtlURL.path) {
            do {
                try fileManager.moveItem(at: mtlURL, to: unzippedArchiveURL.appendingPathComponent(friendlyFilenameBasenameWithCaption + ".mtl"))
            } catch let error as NSError {
                NSLog("Error renaming MTL file: %@ %@", error, error.userInfo)
                return false
            }
        }
        
        return true
    }
    
    func zipContentsOfDirectoryAtURL(_ unzippedArchiveURL: URL, toFileAtURL destinationURL: URL, andAssignDataTo asset: OGAsset) -> Bool {
        if !SSZipArchive.createZipFile(atPath: destinationURL.path, withContentsOfDirectory: unzippedArchiveURL.path) {
            NSLog("Error writing asset model zip to file.")
            return false
        }
        
        defer {
            do {
                try FileManager.default.removeItem(at: destinationURL)
            } catch _ {}
        }
        do {
            let asset = OGDatabaseManager.asset(for: asset.id)
            asset?.data = try Data(contentsOf: URL(fileURLWithPath: destinationURL.path), options: NSData.ReadingOptions.init(rawValue: 0))
            OGDatabaseManager.save(asset)
        } catch let error as NSError {
            NSLog("Error reading asset model data from file: %@ %@", error, error.userInfo)
            return false
        }
        
        return true
    }
    
    
    // MARK: - Privates
    
    func tmpDirURL() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(self.id)
    }
}
