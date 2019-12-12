//
//  OGClinic+ListItem.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 08.12.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import FontAwesomeKit

extension OGClinic: SimpleListItem {

    var cellDisplayText: String {
        get { return self.name }
    }

    var cellDisplayImage: UIImage {
        get {
            return FAKIonIcons.iosHomeIcon(withSize: 64).image(with: CGSize(width: 80, height: 80))
        }
    }
    
}
