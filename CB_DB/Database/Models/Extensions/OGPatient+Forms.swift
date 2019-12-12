//
//  Patient+Forms.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-03.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import XLForm

extension OGPatient: FormLoadable {
    
    enum FormRowTags: String {
        case FirstName
        case LastName
        case DateOfBirth
        case Weight
        case WeightUnit
        case Gender
        case FootTemplateSizeLeft
        case FootTemplateSizeRight
        case Notes
        case ViewOrdersButton
        case ResetOrderButton
        case SubmitOrderButton
    }
    
    
    // MARK: - Publics
    
    static func formDescriptorPatientInfoEditWithPatient(_ patient: OGPatient) -> XLFormDescriptor {
        let descriptor: XLFormDescriptor = self.formDescriptorForPatient(patient)
        descriptor.assignFirstResponderOnShow = false
        
        let section: XLFormSectionDescriptor = XLFormSectionDescriptor.formSection()
        descriptor.addFormSection(section)
        
        var row: XLFormRowDescriptor
            
        row = XLFormRowDescriptor(tag: FormRowTags.ViewOrdersButton.rawValue,
                                    rowType: XLFormRowDescriptorTypeButton,
                                    title: NSLocalizedString("XLFViewPreviousOrders", comment: "View previous orders button title"))
        section.addFormRow(row)
        
        descriptor.addFormSection(section)
        row = XLFormRowDescriptor(tag: FormRowTags.ResetOrderButton.rawValue,
            rowType: XLFormRowDescriptorTypeButton,
            title: NSLocalizedString("OResetButton", comment: "Reset order button"))
        row.cellConfig["textLabel.textColor"] = UIColor.red
        section.addFormRow(row)
        
        return descriptor
    }
    
    static func formDescriptorPatientInfoAddNew() -> XLFormDescriptor {
        let descriptor: XLFormDescriptor = self.formDescriptorForPatient(nil)
        descriptor.assignFirstResponderOnShow = true
        
        return descriptor
    }

    func loadValuesFromForm(_ form: XLFormDescriptor, sectionName: String?) {

        var row: XLFormRowDescriptor
        row = form.formRow(withTag: FormRowTags.FirstName.rawValue)!
        self.firstName = row.value as! String
        row = form.formRow(withTag: FormRowTags.LastName.rawValue)!
        self.lastName = row.value as! String
        row = form.formRow(withTag: FormRowTags.DateOfBirth.rawValue)!
        self.dateOfBirth = row.value as! Date
        row = form.formRow(withTag: FormRowTags.Weight.rawValue)!
        self.weight = Int(row.value as! NSNumber)
        row = form.formRow(withTag: FormRowTags.WeightUnit.rawValue)!
        self.weightUnit = row.value as! String
        row = form.formRow(withTag: FormRowTags.Gender.rawValue)!
        self.gender = row.value as! String
        if let row = form.formRow(withTag: FormRowTags.FootTemplateSizeLeft.rawValue), let value = row.value as? XLFormOptionsObject {
            self.footTemplateSizeLeft = Float(value.formValue() as? NSDecimalNumber ?? NSDecimalNumber(integerLiteral: 0))
        }
        if let row = form.formRow(withTag: FormRowTags.FootTemplateSizeRight.rawValue), let value = row.value as? XLFormOptionsObject {
            self.footTemplateSizeRight = Float(value.formValue() as? NSDecimalNumber ?? NSDecimalNumber(integerLiteral: 0))
        }
        row = form.formRow(withTag: FormRowTags.Notes.rawValue)!
        self.notes = row.value as? String ?? ""
    }
    
    
    // MARK: - Privates
    
    static func formDescriptorForPatient(_ patient: OGPatient?) -> XLFormDescriptor {
        let formDescriptor: XLFormDescriptor = XLFormDescriptor()
        var section: XLFormSectionDescriptor
        var row: XLFormRowDescriptor
        
        section = XLFormSectionDescriptor.formSection()
        formDescriptor.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: FormRowTags.FirstName.rawValue,
                                    rowType: XLFormRowDescriptorTypeName,
                                    title: NSLocalizedString("XLFFirstName", comment: "First name form label"))
        row.isRequired = true
        if patient != nil {
            row.value = patient!.firstName as String
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: FormRowTags.LastName.rawValue,
                                    rowType: XLFormRowDescriptorTypeName,
                                    title: NSLocalizedString("XLFLastName", comment: "Last name form label"))
        row.isRequired = true
        if patient != nil {
            row.value = patient!.lastName as String
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: FormRowTags.DateOfBirth.rawValue,
                                    rowType: XLFormRowDescriptorTypeDate,
                                    title: NSLocalizedString("XLFDateOfBirth", comment: "DOB form label"))
        row.isRequired = true
        if patient != nil {
            row.value = patient!.dateOfBirth as Date
        } else {
            var defaultComponents = DateComponents()
            defaultComponents.year = 1990
            defaultComponents.month = 1
            defaultComponents.day = 1
            row.value = Calendar.current.date(from: defaultComponents)
        }
        var minComponents = DateComponents()
        minComponents.year = 1930
        minComponents.month = 1
        minComponents.day = 1
        row.cellConfig["minimumDate"] = Calendar.current.date(from: minComponents)
        row.cellConfig["maximumDate"] = Date()
        self.configureRow(row)
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: FormRowTags.Weight.rawValue,
                                    rowType: XLFormRowDescriptorTypeInteger,
                                    title: NSLocalizedString("XLFWeight", comment: "Weight form label"))
        row.isRequired = true
        if patient != nil {
            row.value = patient!.weight
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: FormRowTags.WeightUnit.rawValue,
                                    rowType: XLFormRowDescriptorTypeSelectorSegmentedControl, title: "")
        row.isRequired = true
        row.selectorOptions = [NSLocalizedString("XLFWeightUnitLb", comment: "Weight unit Lb"), NSLocalizedString("XLFWeightUnitKg", comment: "Weight unit Kg")]
        row.value = (patient == nil) ? NSLocalizedString("XLFWeightUnitLb", comment: "Weight unit Lb") : patient!.weightUnit

        self.configureRow(row)
        section.addFormRow(row)
        
        row = XLFormRowDescriptor(tag: FormRowTags.Gender.rawValue,
                                    rowType: XLFormRowDescriptorTypeSelectorSegmentedControl,
                                    title: NSLocalizedString("XLFGender", comment: "Gender form label"))
        row.isRequired = true
        row.selectorOptions = [NSLocalizedString("XLFGenderMale", comment: "Gender male"), NSLocalizedString("XLFGenderFemale", comment: "Gender female")]
        row.value = (patient == nil) ? NSLocalizedString("XLFGenderMale", comment: "Gender male") : patient!.gender
        self.configureRow(row)
        section.addFormRow(row)
        
        let footSizeConversions = [ // Canada/US -> Euro
            14:     "Kids 1 - 1.5",
            14.5:   "Kids 1 - 1.5",
            15:     "Kids 1 - 1.5",
            15.5:   "Kids 1 - 1.5",
            16:     "Kids 1 - 1.5",
            16.5:   "Kids 1 - 1.5",
            17:     "Kids 1 - 1.5",
            17.5:   "Kids 1 - 1.5",
            18:     "Kids 1 - 1.5",
            18.5:   "Kids 1 - 1.5",
            19:     "Kids 1.5 - 2",
            19.5:   "Kids 2 - 2.5",
            20:     "Kids 2.5 - 3",
            20.5:   "Kids 3 - 3.5",
            21:     "Kids 3.5 - 4",
            21.5:   "Kids 4 - 4.5",
            22:     "Kids 4.5 - 5",
            22.5:   "Kids 5 - 5.5",
            23:     "Kids 5.5 - 6",
            23.5:   "Kids 6 - 6.5",
            24:     "Kids 6.5 - 7",
            24.5:   "Kids 7 - 7.5",
            25:     "Kids 7.5 - 8",
            25.5:   "Kids 8 - 8.5",
            26:     "Kids 8.5 - 9",
            26.5:   "Kids 9 - 9.5",
            27:     "Kids 9.5 - 10",
            27.5:   "Kids 10 - 10.5",
            28:     "Kids 10.5 - 11",
            28.5:   "Kids 11 - 11.5",
            29:     "Kids 11.5 - 12",
            29.5:   "Kids 12 - 12.5",
            30:     "Kids 12.5 - 13",
            30.5:   "Kids 13",
            31:     "Kids 13",
            31.5:   "Kids 13",

            32:     "Women's 2 - 2.5 / Men's 1 - 1.5",
            32.5:   "Women's 2 - 2.5 / Men's 1 - 1.5",
            33:     "Women's 2.5 - 3 / Men's 1.5 - 2",
            33.5:   "Women's 3 - 3.5 / Men's 2 - 2.5",
            34:     "Women's 3.5 - 4 / Men's 2.5 - 3",
            34.5:   "Women's 4 - 4.5 / Men's 2.5 - 3",
            35:     "Women's 4.5 - 5 / Men's 3 - 3.5",
            35.5:   "Women's 5 - 5.5 / Men's 3.5 - 4",
            36:     "Women's 5.5 - 6 / Men's 4 - 4.5",
            36.5:   "Women's 6 - 6.5 / Men's 4.5 - 5",
            37:     "Women's 6.5 - 7 / Men's 5 - 5.5",
            37.5:   "Women's 7 - 7.5 / Men's 5 - 5.5",
            38:     "Women's 7.5 - 8 / Men's 5.5 - 6",
            38.5:   "Women's 8 - 8.5 / Men's 6 - 6.5",
            39:     "Women's 8.5 - 9 / Men's 6.5 - 7",
            39.5:   "Women's 9 - 9.5 / Men's 7 - 7.5",

            40:     "Women's 9.5 - 10 / Men's 7 - 7.5",
            40.5:   "Women's 10 - 10.5 / Men's 7.5 - 8",
            41:     "Women's 10.5 - 11 / Men's 8 - 8.5",
            41.5:   "Women's 11 - 11.5 / Men's 8.5 - 9",
            42:     "Women's 11.5 - 12 / Men's 9 - 9.5",
            42.5:   "Women's 12 - 12.5 / Men's 9 - 9.5",
            43:     "Women's 12.5 - 13 / Men's 9.5 - 10",
            43.5:   "Women's 13 - 13.5 / Men's 10 - 10.5",
            44:     "Women's 13.5 - 14 / Men's 10.5 - 11",
            44.5:   "Women's 14 - 14.5 / Men's 11 - 11.5",

            45:     "Women's 14.5 - 15 / Men's 11.5 - 12",
            45.5:   "Women's 15 - 15.5 / Men's 12 - 12.5",
            46:     "Women's 15.5 - 16 / Men's 12.5 - 13",
            46.5:   "Women's 16 - 16.5 / Men's 13 - 13.5",
            47:     "Women's 16.5 - 17 / Men's 13.5 - 14",
            47.5:   "Women's 17 - 17.5 / Men's 14 - 14.5",
            48:     "Women's 17.5 - 18 / Men's 14.5 - 15",
            48.5:   "Women's 18 - 18.5 / Men's 15 - 15.5",
            49:     "Women's 18.5 - 19 / Men's 15.5 - 16",
            49.5:   "Women's 19 - 19.5 / Men's 16 - 16.5",
            50:     "Women's 19.5 - 20 / Men's 16.5 - 17"
        ]

        let footSizeSelectorOptions = footSizeConversions.keys.sorted().map { (euro) -> XLFormOptionsObject in
            let usString = footSizeConversions[euro]!
            let euroString = floor(euro) == euro ? String(format: "%.0f", euro) : String(format: "%.1f", euro)
            return XLFormOptionsObject(value: NSDecimalNumber(value: euro as Double), displayText: "Euro \(euroString) (\(usString))")
        }

        row = XLFormRowDescriptor(tag: FormRowTags.FootTemplateSizeLeft.rawValue,
                                    rowType: XLFormRowDescriptorTypeSelectorPickerView,
                                    title: NSLocalizedString("XLFFootTemplateSizeLeft", comment: "Foot template size left form label"))
        row.isRequired = true
        row.selectorOptions = footSizeSelectorOptions
        if let patient = patient {
            let templateSize = "\(patient.footTemplateSizeLeft)"
            row.value = XLFormOptionsObject(value: patient.footTemplateSizeLeft, displayText: "\(templateSize)")
        } else {
            row.value = XLFormOptionsObject(value: NSDecimalNumber(value: 38 as Double), displayText: "38")
        }
        self.configureRow(row)
        section.addFormRow(row)

        row = XLFormRowDescriptor(tag: FormRowTags.FootTemplateSizeRight.rawValue,
                                    rowType: XLFormRowDescriptorTypeSelectorPickerView,
                                    title: NSLocalizedString("XLFFootTemplateSizeRight", comment: "Foot template size right form label"))
        row.isRequired = true
        row.selectorOptions = footSizeSelectorOptions
        if let patient = patient {
            let templateSize = "\(patient.footTemplateSizeRight)"
            row.value = XLFormOptionsObject(value: patient.footTemplateSizeRight, displayText: "\(templateSize)")
        } else {
            row.value = XLFormOptionsObject(value: NSDecimalNumber(value: 38 as Double), displayText: "38")
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        
        row = XLFormRowDescriptor(tag: FormRowTags.Notes.rawValue,
                                    rowType: XLFormRowDescriptorTypeTextView,
                                    title: NSLocalizedString("XLFNotes", comment: "Notes form label"))
        row.isRequired = false
        if patient != nil {
            row.value = patient!.notes
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        return formDescriptor
    }
    
    static func configureRow(_ row: XLFormRowDescriptor) {
        row.cellConfig["textLabel.textColor"] = UIColor.gray
        row.cellConfig["textLabel.font"] = UIFont.boldSystemFont(ofSize: 14.0)
    }
    
}
