//
//  Practitioner.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-03.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import UIKit
import FontAwesomeKit

extension OGPractitioner: SimpleListItem {
    
    var cellDisplayText: String {
        get { return self.name ?? "" }
    }
    
    var cellDisplayImage: UIImage {
        get { return FAKIonIcons.medkitIcon(withSize: 64)?.image(with: CGSize(width: 64, height: 64)) ?? UIImage() }
    }
    
}
