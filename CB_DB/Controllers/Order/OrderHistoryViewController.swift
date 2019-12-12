//
//  OrderHistoryViewController.swift
//  Scanner
//
//  Created by Ernest Surudo on 2015-09-08.
//  Copyright © 2015 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import FontAwesomeKit

protocol OrderHistoryViewControllerDelegate {
    func dismissOrderHistoryViewController(_ controller: OrderHistoryViewController)
    func orderHistoryViewController(_ controller: OrderHistoryViewController, requestsLoadOrder order: OGOrder)
}

class OrderHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var delegate: OrderHistoryViewControllerDelegate?
    var patient: OGPatient!
        
    var _shortStyleDateFormatter:DateFormatter =  {
        var date = DateFormatter()
        date.dateStyle = .short
        return date
    }()
    
    var _checkmarkImage: UIImage!
    
    var orders = [OGOrder]()
    
    @IBOutlet var tableView: UITableView!
    
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let checkmarkIcon = FAKIonIcons.checkmarkIcon(withSize: 64)
        self._checkmarkImage = checkmarkIcon?.image(with: CGSize(width: 80, height: 80))
        self.performFetch()
    }
    
    
    // MARK: - Table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orders.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset = UIEdgeInsets.zero
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            let order = orders[indexPath.row]
            OGDatabaseManager.delete(order)
        }
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let order = orders[indexPath.row]
        let uniqueID: String = order.id
        cell.textLabel!.text = "Order \(uniqueID)"
        var stringDate = ""
        if let date = order.submittedAt?.dateWithFormat(DateFormat.iso8601){
           stringDate = self._shortStyleDateFormatter.string(from: date)
        }
        cell.detailTextLabel!.text = "\("HSubmittedOn".localized()) \(stringDate)"
        cell.imageView!.image = self._checkmarkImage
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actionAlertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let loadAction: UIAlertAction = UIAlertAction(title: "HLoadPreviousOrder".localized(),
                                                      style: UIAlertAction.Style.default,
                                                        handler: {(action: UIAlertAction) in
                                                            let loadAlertController: UIAlertController = UIAlertController(title: NSLocalizedString("HLoadPreviousOrderTitle", comment: "Load previous order title"), message: NSLocalizedString("HLoadPreviousOrderMessage", comment: "Load previous order message"), preferredStyle: UIAlertController.Style.alert)
                                                            let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("CCancel", comment: "Cancel"), style: UIAlertAction.Style.cancel, handler: nil)
            let proceedAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("HLoadPreviousOrder", comment: "Load previous order"),
                                                             style: UIAlertAction.Style.destructive,
                                                                handler: {(action: UIAlertAction) in
                                                                    let order: OGOrder = self.orders[indexPath.row]
                    self.delegate?.orderHistoryViewController(self, requestsLoadOrder: order)
            })
            loadAlertController.addAction(cancelAction)
            loadAlertController.addAction(proceedAction)
            self.present(loadAlertController, animated: true, completion: nil)
            
        })
        actionAlertController.addAction(loadAction)
        actionAlertController.popoverPresentationController!.permittedArrowDirections = UIPopoverArrowDirection(rawValue: UIPopoverArrowDirection.up.rawValue | UIPopoverArrowDirection.down.rawValue)
        actionAlertController.popoverPresentationController!.sourceView = tableView
        actionAlertController.popoverPresentationController!.sourceRect = tableView.rectForRow(at: indexPath)
        self.present(actionAlertController, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func tappedClose(_ sender: AnyObject) {
        self.delegate?.dismissOrderHistoryViewController(self)
    }
    
    func performFetch() {
        orders = OGDatabaseManager.allOrders(for: patient)
        tableView.reloadData()
    }
    
}
