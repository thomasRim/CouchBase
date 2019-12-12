//
//  Practitioner+Forms.swift
//  Scanner
//
//  Created by Ernest Surudo on 2016-03-04.
//  Copyright © 2016 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import XLForm

extension OGPractitioner: FormLoadable {
    
    enum FormRowTags: String {
        case Name
    }
    
    static func formDescriptorForPractitioner(_ practitioner: OGPractitioner?) -> XLFormDescriptor {
        let formDescriptor: XLFormDescriptor = XLFormDescriptor()
        var section: XLFormSectionDescriptor
        var row: XLFormRowDescriptor
        
        formDescriptor.assignFirstResponderOnShow = (practitioner == nil)
        
        section = XLFormSectionDescriptor.formSection()
        formDescriptor.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: FormRowTags.Name.rawValue,
            rowType: XLFormRowDescriptorTypeName,
            title: NSLocalizedString("XLFName", comment: "Name"))
        row.isRequired = true
        if let practitioner = practitioner, practitioner.name != nil {
            row.value = practitioner.name
        }
        self.configureRow(row)
        section.addFormRow(row)
        
        return formDescriptor
    }
    
    func loadValuesFromForm(_ form: XLFormDescriptor, sectionName: String?) {
        var row: XLFormRowDescriptor
        row = form.formRow(withTag: FormRowTags.Name.rawValue)!
        self.name = row.value as? String
    }
    
    static func configureRow(_ row: XLFormRowDescriptor) {
        row.cellConfig["textLabel.textColor"] = UIColor.gray
        row.cellConfig["textLabel.font"] = UIFont.boldSystemFont(ofSize: 14.0)
    }
    
}
