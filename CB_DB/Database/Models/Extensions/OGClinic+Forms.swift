//
//  Clinic+Forms.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-10-13.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import XLForm

extension OGClinic: FormLoadable {
    
    enum FormRowTags: String {
        case Name
        case Address
        case City
        case Province
        case PostalCode
        case ContactEmail
        case PhoneNumber

    }
    
    static func formDescriptorForClinic(_ clinic: OGClinic?) -> XLFormDescriptor {
        let formDescriptor: XLFormDescriptor = XLFormDescriptor()
        var section: XLFormSectionDescriptor
        var row: XLFormRowDescriptor
        
        formDescriptor.assignFirstResponderOnShow = (clinic == nil)
        
        section = XLFormSectionDescriptor.formSection()
        formDescriptor.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: FormRowTags.Name.rawValue,
                                    rowType: XLFormRowDescriptorTypeName,
                                    title: NSLocalizedString("XLFName", comment: "Name"))
        row.isRequired = true
        if let clinic = clinic { // TODO can get rid of second condition after migration
            row.value = clinic.name
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: FormRowTags.Address.rawValue,
                                    rowType: XLFormRowDescriptorTypeName,
                                    title: NSLocalizedString("XLFAddress", comment: "Address"))
        if clinic != nil && clinic!.address != nil { // TODO can get rid of second condition after migration
            row.value = clinic!.address
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: FormRowTags.City.rawValue,
                                    rowType: XLFormRowDescriptorTypeName,
                                    title: NSLocalizedString("XLFCity", comment: "City"))
        if clinic != nil && clinic!.city != nil { // TODO can get rid of second condition after migration
            row.value = clinic!.city
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: FormRowTags.Province.rawValue,
                                    rowType: XLFormRowDescriptorTypeSelectorPickerView,
                                    title: NSLocalizedString("XLFProvince", comment: "Province"))
        row.selectorOptions = ["XLFProvinceBritishColumbia", "XLFProvinceAlberta", "XLFProvinceSaskatchewan", "XLFProvinceManitoba", "XLFProvinceOntario", "XLFProvinceQuebec", "XLFProvinceNewBrunswick", "XLFProvinceNewfoundlandAndLabrador", "XLFProvinceNovaScotia", "XLFProvincePrinceEdwardIsland", "XLFProvinceYukon", "XLFProvinceNorthwestTerritories", "XLFProvinceNunavut"].map({ (province: String) -> XLFormOptionsObject in
            XLFormOptionsObject(value: province, displayText: NSLocalizedString(province, comment: "<dynamic>"))
        }).sorted(by: { $0.displayText() < $1.displayText() })
        if clinic != nil {
            if clinic!.province != nil { // TODO can get rid of second condition after migration
                row.value = XLFormOptionsObject(value: clinic!.province, displayText: NSLocalizedString(clinic!.province ?? "", comment: "<dynamic>"))
            }
        } else {
            row.value = XLFormOptionsObject(value: "XLFProvinceAlberta", displayText: NSLocalizedString("XLFProvinceAlberta", comment: "Alberta"))
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: FormRowTags.PostalCode.rawValue,
                                    rowType: XLFormRowDescriptorTypeText,
                                    title: NSLocalizedString("XLFPostalCode", comment: "Postal code"))
        if clinic != nil && clinic!.postalCode != nil { // TODO can get rid of second condition after migration
            row.value = clinic!.postalCode
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: FormRowTags.ContactEmail.rawValue,
                                    rowType: XLFormRowDescriptorTypeEmail,
                                    title: NSLocalizedString("XLFEmail", comment: "Contact email"))
        if clinic != nil && clinic!.contactEmail != nil { // TODO can get rid of second condition after migration
            row.value = clinic!.contactEmail
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        let emailValidator = XLFormRegexValidator.init(msg: "Email must be valid", regex: "^[^@]+@[^@]+$")
        row.addValidator(emailValidator!)
        
        row = XLFormRowDescriptor(tag: FormRowTags.PhoneNumber.rawValue,
                                    rowType: XLFormRowDescriptorTypePhone,
                                    title: NSLocalizedString("XLFPhoneNumber", comment: "Phone number"))
        if clinic != nil && clinic!.phoneNumber != nil { // TODO can get rid of second condition after migration
            row.value = clinic!.phoneNumber
        }
        self.configureRow(row)
        section.addFormRow(row)

        return formDescriptor
    }
    
    func loadValuesFromForm(_ form: XLFormDescriptor) {
        var row: XLFormRowDescriptor
        row = form.formRow(withTag: FormRowTags.Name.rawValue)!
        self.name = row.value as! String
        row = form.formRow(withTag: FormRowTags.Address.rawValue)!
        self.address = row.value as? String
        row = form.formRow(withTag: FormRowTags.City.rawValue)!
        self.city = row.value as? String
        row = form.formRow(withTag: FormRowTags.Province.rawValue)!
        self.province = (row.value as! XLFormOptionsObject).formValue() as? String
        row = form.formRow(withTag: FormRowTags.PostalCode.rawValue)!
        self.postalCode = row.value as? String
        row = form.formRow(withTag: FormRowTags.ContactEmail.rawValue)!
        self.contactEmail = row.value as? String
        row = form.formRow(withTag: FormRowTags.PhoneNumber.rawValue)!
        self.phoneNumber = row.value as? String

        OGDatabaseManager.save(self)
    }
    
    static func configureRow(_ row: XLFormRowDescriptor) {
        row.cellConfig["textLabel.textColor"] = UIColor.gray
        row.cellConfig["textLabel.font"] = UIFont.boldSystemFont(ofSize: 14.0)
    }
    
}
