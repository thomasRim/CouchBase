//
//  UIAlertController+OKCancel.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-04.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertController {
    
    static let defaultCancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel)
    static let defaultOkAction = UIAlertAction(title: "Ok", style: UIAlertAction.Style.cancel)
    
    convenience init(title: String?, message: String?, preferredStyle: UIAlertController.Style = .alert,
        cancelLabel: String? = nil, cancelAlertHandler: ((UIAlertAction) -> Void)? = nil, okLabel: String? = nil, okAlertHandler: ((UIAlertAction) -> Void)? = nil)
    {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        
        if cancelLabel != nil {
            self.addAction(UIAlertAction(title: cancelLabel, style: UIAlertAction.Style.cancel, handler: cancelAlertHandler))
        }
        
        if okLabel != nil {
            self.addAction(UIAlertAction(title: okLabel, style: UIAlertAction.Style.default, handler: okAlertHandler))
        }
        
        if cancelLabel == nil && okLabel == nil {
            self.addAction(UIAlertController.defaultOkAction)
        }
    }
}

extension UIAlertController {
    
    @objc static func showAlert(title: String? = nil, message: String? = nil, preferredStyle: UIAlertController.Style = .alert, actions:[UIAlertAction]? = nil, from:UIViewController? = nil) {

        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        
        if let actions = actions {
            actions.forEach{alert.addAction($0)}
        } else {
            alert.addAction(defaultOkAction)
        }
        DispatchQueue.main.async {
            let vc = from != nil ? from : UIApplication.shared.windows[0].rootViewController
            vc?.present(alert, animated: true)
        }
    }
    
    static func showCredentialAlert(title:String?, message:String?, inputFields:[UITextField]? = nil, actions:[UIAlertAction]? = nil, from:UIViewController? = nil) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message:  message, preferredStyle: UIAlertController.Style.alert)
        
        if let textFields = inputFields {
            for var field in textFields {
                alert.addTextField(configurationHandler: { (textField) in
                    textField.placeholder = field.placeholder
                    textField.text = field.text
                    textField.textColor = field.textColor
                    textField.textAlignment = field.textAlignment
                    textField.isSecureTextEntry = field.isSecureTextEntry
                    field = textField
                })
            }
        }
        
        
        if let actions = actions {
            actions.forEach{alert.addAction($0)}
        } else {
            alert.addAction(defaultCancelAction)
        }
        
        DispatchQueue.main.async {
            let vc = from != nil ? from : UIApplication.shared.windows[0].rootViewController
            vc?.present(alert, animated: true)
        }
        
        return alert
        
    }
    
    @objc static func showBatteryLowEnergyAlert() {
        let alert = UIAlertController(title: "Structure Sensor", message:  "Low Battery (5%).\n Please Charge Structure Sensor\n\n\n", preferredStyle: .alert)
        alert.addAction(defaultOkAction)
        
        let image = #imageLiteral(resourceName: "battery-05")
        let iv = UIImageView(image: image)
        
        iv.frame = CGRect(x: 0, y: 80, width: 260, height: 40)
        iv.contentMode = .scaleAspectFit
        
        alert.view.addSubview(iv)
        
        DispatchQueue.main.async {
            let vc = UIApplication.shared.windows[0].rootViewController
            vc?.present(alert, animated: true)
        }
    }
}

