//
//  PractitionerViewEditViewController.swift
//  Scanner
//
//  Created by Ernest Surudo on 2016-03-04.
//  Copyright © 2016 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import XLForm

protocol PractitionerNewEditViewControllerDelegate {
    func practitionerNewEditViewController(_ controller: PractitionerNewEditViewController, didAddPractitioner practitioner: OGPractitioner)
    func practitionerNewEditViewController(_ controller: PractitionerNewEditViewController, didUpdatePractitioner practitioner: OGPractitioner)
    func practitionerNewEditViewControllerDidCancelEntry(_ controller: PractitionerNewEditViewController)
}

extension PractitionerNewEditViewControllerDelegate {
    func practitionerNewEditViewController(_ controller: PractitionerNewEditViewController, didAddPractitioner practitioner: OGPractitioner) {}
    func practitionerNewEditViewController(_ controller: PractitionerNewEditViewController, didUpdatePractitioner practitioner: OGPractitioner) {}
}

class PractitionerNewEditViewController : XLFormViewController {
    
    var delegate: PractitionerNewEditViewControllerDelegate?
    var currentPractitioner: OGPractitioner?
    
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initializeForm()
        
        self.navigationItem.title = (self.currentPractitioner == nil) ? NSLocalizedString("XLFNewPractitioner", comment: "New Practitioner") : NSLocalizedString("XLFEditPractitioner", comment: "Edit Practitioner")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.save,
            target: self, action: #selector(savePressed(_:)))
    }
    
    override func didSelectFormRow(_ formRow: XLFormRowDescriptor) {
        super.didSelectFormRow(formRow)
        
        //        if formRow.tag == Practitioner.FormRowTags.SaveButton.rawValue {
        //            self.deselectFormRow(formRow)
        //            self.savePressed(self)
        //        }
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
            if self.currentPractitioner == nil {
                let practitioner = OGPractitioner()
                practitioner.loadValuesFromForm(self.form)
                OGDatabaseManager.save(practitioner)
                self.delegate?.practitionerNewEditViewController(self, didAddPractitioner: practitioner)
            } else {
                self.currentPractitioner?.loadValuesFromForm(self.form)
                OGDatabaseManager.save(currentPractitioner)
                self.delegate?.practitionerNewEditViewController(self, didUpdatePractitioner: self.currentPractitioner!)
            }
        }
    }
    
    @IBAction func closePressed(_ sender: AnyObject) {
        self.view.endEditing(true)
        let alertController = UIAlertController(title: NSLocalizedString("PCloseAlertTitle", comment: "Are you sure?"),
            message: NSLocalizedString("PCloseAlertMessage", comment: "Data will be lost"),
            preferredStyle: UIAlertController.Style.alert,
            cancelLabel: NSLocalizedString("CCancel", comment: "Cancel"), cancelAlertHandler: nil,
            okLabel: NSLocalizedString("PCloseAlertCloseButton", comment: "Close")) { (action) -> Void in
                self.delegate?.practitionerNewEditViewControllerDidCancelEntry(self)
        }
        self.present(alertController, animated: true) { () -> Void in }
    }
    
    
    // MARK: - Privates
    
    func initializeForm() {
        self.form = OGPractitioner.formDescriptorForPractitioner(self.currentPractitioner)
        self.form.delegate = self
    }
    
}
