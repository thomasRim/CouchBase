//
//  PatientInfoFormViewController.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-04.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import XLForm

protocol PatientEditViewControllerDelegate {
    func patientEditViewController(_ controller: PatientEditViewController, didUpdatePatient patient: OGPatient?)
}

class PatientEditViewController : XLFormViewController, OrderHistoryViewControllerDelegate {
    
    private var patientNew = false
    var patient: OGPatient? {
        willSet {
            if patient?.id != newValue?.id {
                patientNew = true
            }
        }
        didSet {
            if patientNew {
                patientNew = false
                self.configureView()
            }
        }
    }
        
    var delegate: PatientEditViewControllerDelegate?
    
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.registerNotifications()
        self.initializeForm()
        self.navigationController!.interactivePopGestureRecognizer!.isEnabled = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("CBack", comment: "Back"), style: UIBarButtonItem.Style.plain,
                                                                target: self, action: #selector(tappedBackButton(_:)))
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false;
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didSelectFormRow(_ formRow: XLFormRowDescriptor) {
        super.didSelectFormRow(formRow)
        
        if formRow.tag == OGPatient.FormRowTags.ViewOrdersButton.rawValue {
            self.deselectFormRow(formRow)
            self.viewPreviousOrdersPressed(self)
        } else if formRow.tag == OGPatient.FormRowTags.ResetOrderButton.rawValue {
            self.deselectFormRow(formRow)
            self.resetOrderPressed(self)
        }
    }
    
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor, oldValue: Any, newValue: Any) {
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)

//        if formRow.tag == Patient.FormRowTags.FootTemplateSizeLeft.rawValue ||
//        formRow.tag == Patient.FormRowTags.FootTemplateSizeRight.rawValue {
//            formRow.value = "\((newValue as? XLFormOptionObject)?.formValue())"
//            self.reloadFormRow(formRow)
//        }
        
        // attempt to save context right on change, to avoid the situation
        // where submission is done, but this context hasn't been saved yet
        var validationErrors: [Any] = self.formValidationErrors()
        if validationErrors.count > 0 {
            self.showFormValidationError(validationErrors[0] as! NSError)
        }
        else {
            self.savePatient()
            
            if formRow.tag == OGPatient.FormRowTags.FirstName.rawValue || formRow.tag == OGPatient.FormRowTags.LastName.rawValue {
                self.updateTitle()
                NotificationCenter.default.post(name: NSNotification.Name.patientNameDidChange, object: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOrderHistory" {
            let controller: OrderHistoryViewController = segue.destination as! OrderHistoryViewController
            controller.patient = self.patient
            controller.delegate = self
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func tappedBackButton(_ sender: AnyObject) {
        var validationErrors: [Any] = self.formValidationErrors()
        if validationErrors.count > 0 {
            self.showFormValidationError(validationErrors[0] as! NSError)
        }
        else {
            self.savePatient()
            self.delegate?.patientEditViewController(self, didUpdatePatient: self.patient)
        }
    }
    
    @IBAction func viewPreviousOrdersPressed(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "showOrderHistory", sender: self)
    }
    
    @IBAction func resetOrderPressed(_ sender: AnyObject) {
        let alertController = UIAlertController(title: NSLocalizedString("CWarning", comment: "Warning"),
            message: NSLocalizedString("OResetMessage", comment: "Reset message"),
            preferredStyle: UIAlertController.Style.alert,
            cancelLabel: NSLocalizedString("CCancel", comment: "Cancel"), cancelAlertHandler: nil,
            okLabel: NSLocalizedString("OResetButton", comment: "Reset"))
            { (action: UIAlertAction) -> Void in

                self.patient?.activeOrder().reset()
                
                NotificationCenter.default.post(name: NSNotification.Name.orderDidChange, object: nil)
        }
        
        self.present(alertController, animated: true) { () -> Void in }
    }
    
    
    // MARK: - OrderHistoryViewControllerDelegate
    
    func dismissOrderHistoryViewController(_ controller: OrderHistoryViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func orderHistoryViewController(_ controller: OrderHistoryViewController, requestsLoadOrder order: OGOrder) {

        self.patient?.activeOrder().duplicateFrom(order: order)

        
        NotificationCenter.default.post(name: NSNotification.Name.orderDidChange, object: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Privates
    
    func registerNotifications() {
    }
    
    func initializeForm() {
        self.form = OGPatient.formDescriptorPatientInfoEditWithPatient(self.patient)
        
        // update segmented control for iOS13
        (self.form.formSections[0] as? XLFormSectionDescriptor)?.formRows.forEach({
            if let cell = ($0 as? XLFormRowDescriptor)?.cell(forForm: self) as? XLFormSegmentedCell {
                if #available(iOS 13.0, *) {
                    cell.segmentedControl.selectedSegmentTintColor = UIColor(with: "#037AFF")
                }
            }
        })
    }
    
    func configureView() {
        if self.patient != nil {
            self.initializeForm()
            self.updateTitle()
        }
    }
    
    func savePatient() {
        self.patient?.loadValuesFromForm(self.form)
        OGDatabaseManager.save(self.patient)
    }
    
    func updateTitle() {
        self.navigationItem.title = self.patient?.name() ?? ""
    }

    
}
