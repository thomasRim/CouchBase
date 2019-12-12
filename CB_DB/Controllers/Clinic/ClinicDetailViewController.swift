//
//  ClinicDetailViewController.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-03.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import UIKit

class ClinicDetailViewController : UIViewController, PractitionerNewEditViewControllerDelegate, ClinicNewEditViewControllerDelegate, SimpleListViewControllerDelegate {
    
    @IBOutlet var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        self.registerNotifications()
        self.configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController!.isNavigationBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "showClinicEdit" {
            let controller = segue.destination as! ClinicNewEditViewController
            controller.delegate = self
            controller.currentClinic = AuthenticationManager.currentClinic
        } else if segue.identifier == "showClinicSwitcher" {
            let currentClinic = AuthenticationManager.currentClinic!
            let controller = segue.destination as! SimpleListViewController
            controller.delegate = self
            controller.showsAddNewButton = false
            controller.items = OGDatabaseManager.allClinics(for: AuthenticationManager.currentPractitioner).filter({ $0.id != currentClinic.id })
        } else if segue.identifier == "showPractitionerEdit" {
            let controller = segue.destination as! PractitionerNewEditViewController
            controller.delegate = self
            controller.currentPractitioner = AuthenticationManager.currentPractitioner
        }
    }
    
    
    // MARK: - ClinicNewEditViewControllerDelegate
    
    func clinicNewEditViewController(_ controller: ClinicNewEditViewController, didUpdateClinic clinic: OGClinic) {
        self.dismiss(animated: true) { () -> Void in
            NotificationCenter.default.post(name: NSNotification.Name.clinicNameDidChange, object: self)
        }
    }
    
    func clinicNewEditViewControllerDidCancelEntry(_ controller: ClinicNewEditViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - PractitionerNewEditViewControllerDelegate
    
    func practitionerNewEditViewController(_ controller: PractitionerNewEditViewController, didUpdatePractitioner practitioner: OGPractitioner) {
        self.dismiss(animated: true) { () -> Void in
//            NSNotificationCenter.defaultCenter().postNotificationName(kClinicNameDidChangeNotification, object: self)
        }
    }
    
    func practitionerNewEditViewControllerDidCancelEntry(_ controller: PractitionerNewEditViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - SimpleListViewControllerDelegate
    
    func simpleListViewController(_ controller: SimpleListViewController, didSelectItem item: SimpleListItem) {
        let clinic = item as? OGClinic
        AuthenticationManager.switchClinic(clinic)
        self.dismiss(animated: true, completion: nil)
    }
    
    func simpleListViewControllerDidClose(_ controller: SimpleListViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Actions
    
    @IBAction func tappedSettingsButton(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        let editClinicAction = UIAlertAction(title: "CEditClinic".localized(), style: UIAlertAction.Style.default) { (action) -> Void in
            self.performSegue(withIdentifier: "showClinicEdit", sender: self)
        }
                
        let editPractitionerAction = UIAlertAction(title: "CEditPractitioner".localized(), style: UIAlertAction.Style.default) { (action) -> Void in
            self.performSegue(withIdentifier: "showPractitionerEdit", sender: self)
        }
        
        let logoutAction = UIAlertAction(title: "CLogout".localized(), style: UIAlertAction.Style.destructive) { (action) -> Void in
            AuthenticationManager.logout()
        }
        
        let actions = [editClinicAction, editPractitionerAction, logoutAction]
        actions.forEach({ alertController.addAction($0) })
        
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.sourceView = self.view
        
        self.present(alertController, animated: true)
    }
    
    
    // MARK: - Privates
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(configureView), name: NSNotification.Name.clinicNameDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(configureView), name: NSNotification.Name.authClinicDidChange, object: nil)
    }
    
    @IBAction fileprivate func configureView() {
        self.navigationItem.title = AuthenticationManager.currentClinic?.name
//        self.versionLabel.text = AppInfo.sharedInfo.versionString
    }
    
}
