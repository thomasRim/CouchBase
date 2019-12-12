//
//  UIImage+size.swift
//  Scanner
//
//  Created by Vladimir Yevdokimov.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func resize(_ newSize:CGSize) -> UIImage {
        return self.resize(newSize, offset: CGPoint.zero)
    }

    func resize(_ newSize:CGSize, offset:CGPoint) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: offset.x, y: offset.y, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return newImage!
    }
}
