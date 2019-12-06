//
//  LoginViewController.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-10-12.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import UIKit

class LoginViewController: UIViewController, SimpleListViewControllerDelegate {
    func simpleListViewControllerDidClose(_ controller: SimpleListViewController) {
        
    }

    
    enum SyncType {
        case upload
        case download
    }
    enum ListControllerId: String {
        case clinic = "clinicList"
        case practitioner = "practitionerList"
    }
        
//    @IBOutlet var sensorBatteryViewController: SensorBatteryViewController!
    
//    @IBOutlet var clinicButton: UIButton!
    @IBOutlet weak var practitionerButton: UIButton?
    @IBOutlet weak var loginButton: UIButton?
    @IBOutlet weak var versionLabel: UILabel?


    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
//        self.registerNotifications()
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)
        print(path)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.addChildViewController(self.sensorBatteryViewController)
        

    }
    

    
    override func viewDidAppear(_ animated: Bool) {
//        self.syncButtonUpdate()
    }
        
    // MARK: - Actions
        
    @IBAction func tappedPractitionerButton(_ sender: AnyObject) {
        let practitionerListViewController = SimpleListViewController()
        practitionerListViewController.controllerId = ListControllerId.practitioner.rawValue
        practitionerListViewController.delegate = self
        practitionerListViewController.items = OGDatabaseManager.allPractitioners() as! [SimpleListItem]
        practitionerListViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        practitionerListViewController.preferredContentSize = CGSize(width: 300, height: 400)
        
        if let popover = practitionerListViewController.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = self.practitionerButton?.frame ?? .zero
        }
        self.present(practitionerListViewController, animated: true)
    }
    
    @IBAction func tappedLoginButton(_ sender: AnyObject) {
//        if AuthenticationManager.currentPractitioner != nil {
//            AuthenticationManager.authenticate()
//        } else {
//            let alertController = UIAlertController(title: "LSelectClinicPractitionerAlertTitle".localized(), message: "LSelectPractitionerAlertMessage".localized(), cancelLabel: "COk".localized())
//            self.present(alertController, animated: true, completion: nil)
//        }
    }
    
    // TEST HTTP METHOD
    @IBAction func pushDataTapped(_ sender: Any) {
//        promptForCredentials(syncType: .upload)
    }

    @IBAction func syncFromServerTapped(_ sender: Any) {
//        let possible: Bool = SyncManager.isDownloadPossible()
//        if (possible)
//        {
//            promptForCredentials(syncType: .download)
//            return;
//        }
//
//        let cancelAction = UIAlertAction(title: "CCancel".localized(), style: .cancel, handler: nil)
//        UIAlertController.showAlert(title: "The app has patient data.\nDownload is only possible in a newly installed app.", message: nil, actions: [cancelAction], from: self)
    }
    
    
    // MARK: - SimpleListViewControllerDelegate
    
    func simpleListViewController(_ controller: SimpleListViewController, didSelectItem item: SimpleListItem) {
        let id = ListControllerId(rawValue: controller.controllerId)
        
        switch id {
        case .clinic: break
        case .practitioner:
            let practitioner = item as? OGPractitioner
//            AuthenticationManager.currentPractitioner = practitioner
//            self.practitionerButton.setTitle("Practitioner: \(practitioner?.name ?? "")", for: UIControlState())
        default: break
        }
        
        self.dismiss(animated: true)
    }
    
    func simpleListViewControllerDidSelectAddNew(_ controller: SimpleListViewController) {
        switch ListControllerId(rawValue: controller.controllerId) {
        case .clinic: break
        case .practitioner:
            self.dismiss(animated: true) { () -> Void in
                self.promptForNewPractitioner()
            }
        default: break
        }
    }
        
    // MARK: - Privates
    
    func promptForNewPractitioner() {
        let alertController = UIAlertController(title: "LNewPractitionerAlertTitle",
                                                message: nil, preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField(configurationHandler: { (textField: UITextField) -> Void in
            textField.placeholder = "LEnterPractitionerName"
            textField.autocapitalizationType = UITextAutocapitalizationType.words
            textField.autocorrectionType = UITextAutocorrectionType.no
            textField.keyboardType = UIKeyboardType.alphabet
        })
        let cancelAction = UIAlertAction(title: "CCancel", style: UIAlertAction.Style.cancel, handler: nil)
        let okAction = UIAlertAction(title: "CDone", style: UIAlertAction.Style.default, handler: { (action) -> Void in
            let name = alertController.textFields![0].text?.trimmingCharacters(in: CharacterSet.whitespaces)

            if let name = name, name.count > 0 {
                var practitioner = OGPractitioner()
                practitioner.name = name
                OGDatabaseManager.save(practitioner.toDocument())
//                AuthenticationManager.currentPractitioner = practitioner
                self.practitionerButton?.setTitle("Practitioner: \(name)", for: UIControl.State.normal)
            } else {
                self.promptForNewPractitioner()
            }
        })
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)

        self.present(alertController, animated: true, completion: nil)
    }
//
//    func promptForCredentials(syncType: SyncType) {
//        var title = ""
//        switch syncType {
//        case .upload:
//            title = "Enter an email and password for use to backup your data"
//        case .download:
//            title = "Enter an email and password for use to restore your backup"
//        default: break
//        }
//
//
//        let alertController = UIAlertController(title: title,
//                                                message: nil, preferredStyle: UIAlertControllerStyle.alert)
//        alertController.addTextField(configurationHandler: { (textField: UITextField) -> Void in
//            textField.placeholder = "Enter an email"
//            textField.text = "" /// !!!
//            textField.autocapitalizationType = UITextAutocapitalizationType.words
//            textField.autocorrectionType = UITextAutocorrectionType.no
//            textField.keyboardType = UIKeyboardType.alphabet
//        })
//        alertController.addTextField(configurationHandler: { (textField: UITextField) -> Void in
//            textField.placeholder = "Enter a password"
//            textField.text = "" // !!!
//            textField.autocapitalizationType = UITextAutocapitalizationType.words
//            textField.autocorrectionType = UITextAutocorrectionType.no
//            textField.keyboardType = UIKeyboardType.alphabet
//        })
//        let cancelAction = UIAlertAction(title: "CCancel".localized(), style: UIAlertActionStyle.cancel, handler: nil)
//        let okAction = UIAlertAction(title: "CDone".localized(), style: UIAlertActionStyle.default, handler: { (action) -> Void in
//            let email = alertController.textFields![0].text?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
//            let password = alertController.textFields![1].text?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
//
//            let params = ["username": email, "password": password]
//
//            if email == "" || password == "" {
//                self.promptForCredentials(syncType: syncType)
//            } else if syncType == .upload {
//                AuthenticationManager.currentPractitioner = nil
//                self.practitionerButton.setTitle("Practitioner: ", for: UIControlState())
//
//                SyncManager.upload(with: params) { result in
//                    print(result)
//                }
//            } else if syncType == .download {
//                SyncManager.getManifestFile(parameters: params, completion: { (manifest) in
//                    let availableSpace = SyncManager.freeDiskSpaceInBytes
//                    var requiredSpace = manifest?.dbSize ?? 0
//                    manifest?.assets.forEach({ requiredSpace += Int64($0.size) })
//
//                    if availableSpace <= requiredSpace {
//                        let alertController = UIAlertController(title: "CWarning".localized(),
//                                                                message: "LNoEnoughFreeSpace".localized(),
//                                                                preferredStyle: UIAlertControllerStyle.alert,
//                                                                cancelLabel: "COk".localized(), cancelAlertHandler: nil,
//                                                                okLabel: nil, okAlertHandler: nil)
//                        self.present(alertController, animated: true, completion: nil)
//                         print("\(manifest?.toJSON() ?? [:])")
//                        return;
//
//                    }
//                    DispatchQueue.main.async{UIApplication.shared.isIdleTimerDisabled = true}
//                    SyncManager.download(with: params, completion: { success, message in
//                        DispatchQueue.main.async{UIApplication.shared.isIdleTimerDisabled = false}
//                        print("Download success: \(success ? "yes":"no"), message: \(message)")
//                    })
//
//                    print("\(manifest?.toJSON() ?? [:])")
//                })
//            }
//        })
//        alertController.addAction(cancelAction)
//        alertController.addAction(okAction)
//
//        self.present(alertController, animated: true, completion: nil)
    }

    
    // MARK: TODO: Abstract into sync implementation
    func registerNotifications() {
//        NotificationCenter.default.addObserver(self, selector: #selector(syncBackupUploadFinished(_:)), name: NSNotification.Name.syncBackupUploadFinish, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(syncBackupFail(_:)), name: NSNotification.Name.syncBackupFail, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(syncBackupUploadProgress(_:)), name: NSNotification.Name.syncBackupProgress, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(syncBackupUploadStarted(_:)), name: NSNotification.Name.syncBackupUploadStart, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(syncBackupDownloadFinished(_:)), name: NSNotification.Name.syncBackupDownloadFinish, object: nil)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(syncBackupDownloadStarted(_:)), name: NSNotification.Name.syncBackupDownloadStart, object: nil)
    }
        
//    @objc func syncBackupUploadStarted(_ notification: Notification) {
//        SVProgressHUD.show(withStatus: "DSUploadStarted".localized())
//    }
//    
//    @objc func syncBackupDownloadStarted(_ notification: Notification) {
//        SVProgressHUD.show(withStatus: "DSDownloadStarted".localized())
//    }
//    
//    @objc func syncBackupDownloadFinished(_ notification: Notification) {
//        SVProgressHUD.dismiss()
//        let alertController = UIAlertController(title: "DSDownloadFinishTitle".localized(), message: "DSDownloadFinishMessage".localized(), preferredStyle: UIAlertController.Style.alert, cancelLabel: "COk".localized(), cancelAlertHandler: nil, okLabel: nil, okAlertHandler: nil)
//        present(alertController, animated: true)
//    }
//    
//    @objc func syncBackupUploadFinished(_ notification: Notification) {
//        SVProgressHUD.dismiss()
//        let alertController = UIAlertController(title: "DSUploadFinishTitle".localized(), message: "DSUploadFinishMessage".localized(), preferredStyle: UIAlertController.Style.alert, cancelLabel: "COk".localized(), cancelAlertHandler: nil, okLabel: nil, okAlertHandler: nil)
//        present(alertController, animated: true)
//    }
//    
//    @objc func syncBackupUploadProgress(_ notification: Notification) {
//        DispatchQueue.main.async{
//            SVProgressHUD.showProgress(((notification.userInfo?[kSyncBackupProgressPercentageKey] as AnyObject).floatValue)!,
//                                       status: (notification.userInfo?[(kSyncBackupProgressCommentKey as AnyObject) as! AnyHashable] as! String).localized())
//        }
//    }
//    
//    @objc func syncBackupFail(_ notification: Notification) {
//        let errorMessage = (notification.userInfo?[kSyncBackupErrorCommentKey] as? String) ?? "DSUploadFailMessage".localized()
//
//        SVProgressHUD.dismiss()
//        
//        let alertController = UIAlertController(
//            title: "DSUploadFailTitle".localized(),
//            message: errorMessage,
//            preferredStyle: UIAlertController.Style.alert,
//            cancelLabel: "COk".localized(),
//            cancelAlertHandler: nil,
//            okLabel: nil,
//            okAlertHandler: nil)
//        present(alertController, animated: true)
//    }

//}
