//
//  OrderTabBarController.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-03.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import UIKit
import FontAwesomeKit

class OrderTabBarController : UITabBarController {
           
    override var selectedViewController: UIViewController? {
        didSet {
            switch selectedIndex {
            case 0:
                self.navigationItem.title = "OScansAndPhotos".localized()
            case 1:
                self.navigationItem.title = "OOrthoticInfo".localized()
            default: break
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        
        let nameLbl = UILabel()
        nameLbl.text = AuthenticationManager.currentPractitioner?.name ?? ""
        nameLbl.textColor = .darkGray
        let button = UIBarButtonItem(customView: nameLbl)
        self.navigationItem.rightBarButtonItem = button
        
        
        viewControllers?.forEach({
            let index = viewControllers?.index(of: $0)
            var title = ""
            var image:UIImage?
            
            switch index {
            case 0:
                title = "OScans".localized()
                image = FAKIonIcons.qrScannerIcon(withSize: 25)?.image(with: CGSize(width: 25, height: 25))
            case 1:
                title = "OOrthoticInfo".localized()
                image = UIImage(named: "orthotic icon")?.resize(CGSize(width: 25, height: 25))
            default: break
            }
            
            $0.tabBarItem = UITabBarItem(title: title, image: image, tag: 0)
        })
    }
    
}
