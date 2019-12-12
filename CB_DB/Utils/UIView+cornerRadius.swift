//
//  UIView+cornerRadius.swift
//  Scanner
//
//  Created by Vladimir Yevdokimov.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//
import Foundation
import UIKit

extension UIView {
    func roundCorners(_ corners:UIRectCorner, radius:CGFloat) {

        let maskPath = UIBezierPath(roundedRect: self.bounds,
                                    byRoundingCorners: corners,
                                    cornerRadii: CGSize(width: radius, height: radius))
        let shape = CAShapeLayer.init()
        shape.path = maskPath.cgPath
        self.layer.mask = shape

    }

    @IBInspectable var cornerRadiusExt: CGFloat {
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
        get {
            return layer.cornerRadius
        }
    }
    @IBInspectable var borderWidthExt: CGFloat{
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable var borderColorExt: UIColor? {
        set {
            layer.borderColor = newValue?.cgColor
        }
        get {
            return UIColor(cgColor: layer.borderColor ?? UIColor.clear.cgColor)
        }
    }

}
