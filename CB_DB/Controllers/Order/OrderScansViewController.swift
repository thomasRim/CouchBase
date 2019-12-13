//
//  OrderScansViewController.swift
//  CB_DB
//
//  Created by Vladimir Yevdokimov on 11.12.2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import UIKit

class OrderScansViewController: UIViewController {
    @IBOutlet weak fileprivate var collectionView: UICollectionView?

    var assets = [OGAsset]()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScanC
    }

}


extension OrderScansViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}

//extension OrderScansViewController: ScanViewControllerDelegate {
//    scanViewController
//}
