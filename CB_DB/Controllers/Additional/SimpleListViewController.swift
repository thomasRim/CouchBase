//
//  SimpleListViewController.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-10-13.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import UIKit

protocol SimpleListItem {
    var cellDisplayText: String { get }
    var cellDisplayImage: UIImage { get }
}

protocol SimpleListViewControllerDelegate {
    func simpleListViewController(_ controller: SimpleListViewController, didSelectItem item: SimpleListItem)
    func simpleListViewControllerDidSelectAddNew(_ controller: SimpleListViewController)
    func simpleListViewControllerDidClose(_ controller: SimpleListViewController)
}

// Optionals
extension SimpleListViewControllerDelegate {
    func simpleListViewControllerDidSelectAddNew(_ controller: SimpleListViewController) {}
    func simpleListViewControllerDidClose(_ controller: SimpleListViewController) {}
}

class SimpleListViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct Constants {
        static let addNewIconImage: UIImage = UIImage()
    }
    
    @IBOutlet var tableView: UITableView!
    
    var delegate: SimpleListViewControllerDelegate?
    var items: [SimpleListItem]!
    var controllerId: String!
    var showsAddNewButton: Bool = true
    
    let CellIdentifier = "itemCell"
    let AddCellIdentifier = "addCell"
    
    
    // MARK: - Overrides
    
    override func loadView() {
        if self.nibName == nil && self.storyboard == nil {
            self.tableView = UITableView()
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.view = self.tableView
        } else {
            super.loadView()
        }
    }
    
    
    // MARK: - Table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.showsAddNewButton ? items.count + 1 : items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if indexPath.row == items.count {
            // add new
            cell = tableView.dequeueReusableCell(withIdentifier: AddCellIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: AddCellIdentifier)
            }
            
            cell?.textLabel?.text = "Add new"//.localized()
            cell?.imageView?.image = Constants.addNewIconImage
        } else {
            // regular cell
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: CellIdentifier)
            }
            
            let item = self.items[indexPath.row]
            cell?.textLabel?.text = item.cellDisplayText
            cell?.imageView?.image = item.cellDisplayImage
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == items.count {
            // add new
            self.delegate?.simpleListViewControllerDidSelectAddNew(self)
        } else {
            // regular cell
            let item = self.items[indexPath.row]
            self.delegate?.simpleListViewController(self, didSelectItem: item)
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func closePressed(_ sender: AnyObject) {
        self.view.endEditing(true)
//        let alertController = UIAlertController(title: "PCloseAlertTitle",//.localized(),
//                                                message: "PCloseAlertMessage",//.localized(),
//                                                preferredStyle: UIAlertController.Style.alert,
//                                                cancelLabel: "CCancel", cancelAlertHandler: nil,
//                                                okLabel: "PCloseAlertCloseButton") { (action) -> Void in
                                                    (self.delegate?.simpleListViewControllerDidClose(self))

//        }
//        self.present(alertController, animated: true) { () -> Void in }
    }
    
}
