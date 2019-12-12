//
//  ClinicNewViewController.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-10-13.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import XLForm

protocol ClinicNewEditViewControllerDelegate {
    func clinicNewEditViewController(_ controller: ClinicNewEditViewController, didAddClinic clinic: OGClinic)
    func clinicNewEditViewController(_ controller: ClinicNewEditViewController, didUpdateClinic clinic: OGClinic)
    func clinicNewEditViewControllerDidCancelEntry(_ controller: ClinicNewEditViewController)
}

extension ClinicNewEditViewControllerDelegate {
    func clinicNewEditViewController(_ controller: ClinicNewEditViewController, didAddClinic clinic: OGClinic) {}
    func clinicNewEditViewController(_ controller: ClinicNewEditViewController, didUpdateClinic clinic: OGClinic) {}
}

class ClinicNewEditViewController : XLFormViewController {
    
    var delegate: ClinicNewEditViewControllerDelegate?
    var currentClinic: OGClinic?
    
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initializeForm()
        
        self.navigationItem.title = (self.currentClinic == nil) ? "XLFNewClinic".localized() : "XLFEditClinic".localized()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.save,
                                                                    target: self, action: #selector(savePressed(_:)))
    }
    
    override func didSelectFormRow(_ formRow: XLFormRowDescriptor) {
        super.didSelectFormRow(formRow)
    }
    
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor, oldValue: Any, newValue: Any) {
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // HACK: iOS 9 fix until XLForm issue addressed: https://github.com/xmartlabs/XLForm/issues/483#issuecomment-138707904
        self.tableView.contentInset.top = self.topLayoutGuide.length
    }
    
    
    // MARK: - Actions
    
    @IBAction func savePressed(_ sender: AnyObject) {
        var validationErrors: [Any] = self.formValidationErrors()
        if validationErrors.count > 0 {
            self.showFormValidationError(validationErrors[0] as! NSError)
        }
        else {
            self.tableView.endEditing(true)
            if self.currentClinic == nil, let practitioner = AuthenticationManager.currentPractitioner {
                let clinic = OGClinic()
                clinic.loadValuesFromForm(self.form)
                clinic.practitionerId = practitioner.id
                OGDatabaseManager.save(clinic)

                self.delegate?.clinicNewEditViewController(self, didAddClinic: clinic)
            } else {
                self.currentClinic?.loadValuesFromForm(self.form)
                OGDatabaseManager.save(self.currentClinic )
                self.delegate?.clinicNewEditViewController(self, didUpdateClinic: self.currentClinic!)
            }
        }
    }
    
    @IBAction func closePressed(_ sender: AnyObject) {
        self.view.endEditing(true)
        let alertController = UIAlertController(title: "PCloseAlertTitle".localized(),
                                                message: "PCloseAlertMessage".localized(),
                                                preferredStyle: UIAlertController.Style.alert,
                                                cancelLabel: "CCancel".localized(), cancelAlertHandler: nil,
                                                okLabel: "PCloseAlertCloseButton".localized()) { (action) -> Void in
            self.delegate?.clinicNewEditViewControllerDidCancelEntry(self)
        }
        self.present(alertController, animated: true) { () -> Void in }
    }
    
    
    // MARK: - Privates
    
    func initializeForm() {
        self.form = OGClinic.formDescriptorForClinic(self.currentClinic)
        self.form.delegate = self
    }
    
}
