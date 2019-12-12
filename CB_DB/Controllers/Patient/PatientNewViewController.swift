//
//  PatientAddFormViewController.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-04.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import XLForm

protocol PatientNewViewControllerDelegate {
    func patientNewViewController(_ controller: PatientNewViewController, didAddPatient patient: OGPatient)
    func patientNewViewControllerDidCancelEntry(_ controller: PatientNewViewController)
}

class PatientNewViewController : XLFormViewController {
    
    var delegate: PatientNewViewControllerDelegate?
    
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initializeForm()
        self.navigationItem.title = NSLocalizedString("XLFNewPatient", comment: "New patient")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.save,
                                                                    target: self, action: #selector(savePressed(_:)))
    }
    
    override func didSelectFormRow(_ formRow: XLFormRowDescriptor) {
        super.didSelectFormRow(formRow)
        
//        if formRow.tag == Patient.FormRowTags.SaveButton.rawValue {
//            self.deselectFormRow(formRow)
//            self.savePressed(self)
//        }
    }
    
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor, oldValue: Any, newValue: Any) {
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
        
        if formRow.tag == OGPatient.FormRowTags.FootTemplateSizeLeft.rawValue {
            let rightTemplateRow: XLFormRowDescriptor = self.form.formRow(withTag: OGPatient.FormRowTags.FootTemplateSizeRight.rawValue)!
            rightTemplateRow.value = newValue
            self.reloadFormRow(rightTemplateRow)
        }
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
            let patient = OGPatient()
            patient.loadValuesFromForm(self.form)
            patient.clinicId = AuthenticationManager.currentClinic?.id ?? ""
            OGDatabaseManager.save(patient)
            self.delegate?.patientNewViewController(self, didAddPatient: patient)
        }
    }
    
    @IBAction func closePressed(_ sender: AnyObject) {
        self.view.endEditing(true)
        let alertController = UIAlertController(title: NSLocalizedString("PCloseAlertTitle", comment: "Are you sure?"),
                                                message: NSLocalizedString("PCloseAlertMessage", comment: "Data will be lost"),
                                                preferredStyle: UIAlertController.Style.alert,
                                                cancelLabel: NSLocalizedString("CCancel", comment: "Cancel"), cancelAlertHandler: nil,
                                                okLabel: NSLocalizedString("PCloseAlertCloseButton", comment: "Close")) { (action) -> Void in
            self.delegate?.patientNewViewControllerDidCancelEntry(self)
        }
        self.present(alertController, animated: true) { () -> Void in }
    }
    
    
    // MARK: - Privates
    
    func initializeForm() {
        self.form = OGPatient.formDescriptorPatientInfoAddNew()
        self.form.delegate = self

        // update segmented control for iOS13
        (self.form.formSections[0] as? XLFormSectionDescriptor)?.formRows.forEach({
            if let cell = ($0 as? XLFormRowDescriptor)?.cell(forForm: self) as? XLFormSegmentedCell {
                if #available(iOS 13.0, *) {
                    cell.segmentedControl.selectedSegmentTintColor = UIColor(with: "#037AFF")
                }
            }
        })
    }
    
}
