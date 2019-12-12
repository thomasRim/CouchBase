//
//  ShortOrderInfoViewController.swift
//  ScannerEnterprise
//
//  Created by Vladimir Evdokimov on 2019-10-23.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import Alamofire
import SVProgressHUD

class ShortOrderInfoViewController: UIViewController {

    enum Toggle {
        case selected
        case unselected

        var color: UIColor {
            switch self {
            case .selected:
                return .lightGray
            default:
                return .white
            }
        }
    }

    class Item: SimpleListItem {
        var cellDisplayText: String = ""
        var cellDisplayImage: UIImage = UIImage()
        init(_ title:String) {
            self.cellDisplayText = title
        }
    }

    enum BtnListTag: Int {
        case ReceivedDate = 0
        case ShipmentType
        case ShipmentPrefs
        case ShipDate
        case DaysNumber
        case OrdersNumber
    }

    @IBOutlet private weak var orderReceivedDateBtn: UIButton?
    @IBOutlet private weak var shippintTypeBtn: UIButton?
    @IBOutlet private weak var shippingPreferenceBtn: UIButton?

    @IBOutlet weak fileprivate var dateSelectingView: UIView?
    @IBOutlet weak fileprivate var daysOrdersSelectingView: UIView?

    @IBOutlet weak fileprivate var shipDateBtn: UIButton?
    @IBOutlet weak fileprivate var daysNumberBtn: UIButton?
    @IBOutlet weak fileprivate var ordersNumberBtn: UIButton?

    @IBOutlet weak fileprivate var toggleOrderDefaultBox: UIView?
    @IBOutlet weak fileprivate var toggleWithShoesBox: UIView?

    @IBOutlet private weak var receiverNotesBase: UIView?
    
    private var receiverNotes: UITextView?

    //MARK: - Lifecicle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.receiverNotes = UITextView(frame: receiverNotesBase?.bounds ?? .zero)
        self.receiverNotes?.backgroundColor = UIColor(with: "#EEEEEF")
        self.receiverNotes?.delegate = self
        if let notes = self.receiverNotes {
            self.receiverNotesBase?.addSubview(notes)
        }
        
        subscribe()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // dates
        setupStoredOrderData()

        // notes
        receiverNotes?.text = AuthenticationManager.currentPatient?.activeOrder().notes
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Actions
    
    @IBAction private func dateBtnDidSelect(_ sender:UIButton) {

        var dateVC: DatePopoverViewController?
        var date:Date? = Date()

        var listVC: SimpleListViewController?
        
        switch sender.tag {
        case BtnListTag.ReceivedDate.rawValue:
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "dateVC") as? DatePopoverViewController {
                date = sender.title(for: .normal)?.dateWithFormat(DateFormat.EEEEMMMMddyyyy.rawValue)
                vc.onChangeDate = { (date) in
                    sender.setTitle((date ?? Date()).stringWithFormat(DateFormat.EEEEMMMMddyyyy), for: .normal)
                    AuthenticationManager.currentPatient?.activeOrder().receivedDate = date?.iso8601DateTime() ?? ""
                }
                dateVC = vc
            }
            
        case BtnListTag.ShipmentType.rawValue:
            listVC = SimpleListViewController()
            listVC?.controllerId = "\(sender.tag)"
            listVC?.items = DeliveryPrefereceType.titles().map({Item($0)})
            listVC?.preferredContentSize = CGSize(width: 300, height: 100)
            
        case BtnListTag.ShipmentPrefs.rawValue:
            listVC = SimpleListViewController()
            listVC?.controllerId = "\(sender.tag)"
            let items = ShippingPrefereceType.titles().map({Item($0)})
            listVC?.items = items
            listVC?.preferredContentSize = CGSize(width: 300, height: 150)

        case BtnListTag.ShipDate.rawValue:
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "dateVC") as? DatePopoverViewController {
                let normalDefaultDate = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 + 24*60*60*5) )

                date = sender.title(for: .normal)?.dateWithFormat(DateFormat.EEEEMMMMddyyyy.rawValue)
                if date == nil { date = normalDefaultDate }
                sender.setTitle( date!.stringWithFormat(DateFormat.EEEEMMMMddyyyy), for: .normal)

                vc.onChangeDate = { (date) in
                    sender.setTitle((date ?? normalDefaultDate).stringWithFormat(DateFormat.EEEEMMMMddyyyy), for: .normal)
                    AuthenticationManager.currentPatient?.activeOrder().preferredShipDate = date?.iso8601DateTime() ?? ""
                }
                dateVC = vc
            }
            
        case BtnListTag.OrdersNumber.rawValue:
            listVC = SimpleListViewController()
            listVC?.controllerId = "\(sender.tag)"
            let items = (2...10).map({Item("\($0)")})
            listVC?.items = items
            listVC?.preferredContentSize = CGSize(width: 80, height: 200)
            
        case BtnListTag.DaysNumber.rawValue:
            listVC = SimpleListViewController()
            listVC?.controllerId = "\(sender.tag)"
            let items = (6...12).map({Item("\($0)")})
            listVC?.items = items
            listVC?.preferredContentSize = CGSize(width: 80, height: 200)
            
        default: break
        }

        if let vc = dateVC {
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.sourceView = sender
            self.present(vc, animated: true)
            vc.date = date ?? Date()
        }

        if let vc = listVC {
            vc.delegate = self
            vc.showsAddNewButton = false
            vc.modalPresentationStyle = UIModalPresentationStyle.popover
            vc.popoverPresentationController?.sourceView = sender
            self.present(vc, animated: true)
        }

    }


    @IBAction fileprivate func toggleCheckbox(WithSender sender: UIButton) {
        switch sender.tag {
        case 0:
            let selected = toggleOrderDefaultBox?.backgroundColor == Toggle.selected.color

            if selected {
                toggleOrderDefaultBox?.backgroundColor = Toggle.unselected.color
            } else {
                toggleOrderDefaultBox?.backgroundColor = Toggle.selected.color
            }
        case 1:
            let selected = toggleWithShoesBox?.backgroundColor == Toggle.selected.color

            AuthenticationManager.currentPatient?.activeOrder().withShoes = !selected

            if selected {
                toggleWithShoesBox?.backgroundColor = Toggle.unselected.color
            } else {
                toggleWithShoesBox?.backgroundColor = Toggle.selected.color
            }
            OGDatabaseManager.save(AuthenticationManager.currentPatient?.activeOrder())

        default: break
        }
        
    }

    @IBAction private func onSubmit(_ sender:AnyObject?) {
        startOrderSubmissionPrompts()
    }

    //MARK: - Private funcs

    private func subscribe() {
        NotificationCenter.default.addObserver(self, selector: #selector(orderSubmissionDidStart(_:)), name: .orderSubmissionDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orderSubmissionProgress(_:)), name: .orderSubmissionProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orderSubmissionDidFail(_:)), name: .orderSubmissionDidFail, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orderSubmissionDidSucceed(_:)), name: .orderSubmissionDidSucceed, object: nil)
    }


    private func setupStoredOrderData() {
        let order = AuthenticationManager.currentPatient?.activeOrder()
        
        // received
        if let dateString = order?.receivedDate , let date = dateString.dateWithFormat(DateFormat.iso8601.rawValue) {
            orderReceivedDateBtn?.setTitle(date.stringWithFormat(DateFormat.EEEEMMMMddyyyy), for: .normal)
        } else {
            let dateString = Date().stringWithFormat(DateFormat.EEEEMMMMddyyyy)
            orderReceivedDateBtn?.setTitle(dateString, for: .normal)
            order?.receivedDate = Date().stringWithFormat(DateFormat.iso8601)
            OGDatabaseManager.save(order)
        }
        
        // ship type
        if let typeStr = order?.deliveryPreferenceType , let type = DeliveryPrefereceType(rawValue: typeStr) {
            let typeIndex = DeliveryPrefereceType.allCases.index(of: type) ?? 0
            shippintTypeBtn?.setTitle(DeliveryPrefereceType.titles()[typeIndex], for: .normal)
        }
        
        // ship prefs
        if let pref = order?.shippingPreferenceType, let type = ShippingPrefereceType(rawValue: pref) {
            let typeIndex = ShippingPrefereceType.allCases.index(of: type) ?? 0
            shippingPreferenceBtn?.setTitle(ShippingPrefereceType.titles()[typeIndex], for: .normal)

            // selection toggle views
            switch typeIndex {
            case 0:
                dateSelectingView?.isHidden = true
                daysOrdersSelectingView?.isHidden = true
            case 1:
                dateSelectingView?.isHidden = true
                daysOrdersSelectingView?.isHidden = false
            case 2:
                dateSelectingView?.isHidden = false
                daysOrdersSelectingView?.isHidden = true
            default:break
            }
        }

        // days to wait
        let days = order?.numberOfDaysToWait ?? 0
        if days > 0 {
            daysNumberBtn?.setTitle("\(days)", for: .normal)
        }
        
        // orders to wait
        let orders = order?.numberOfOrdersToWait ?? 0
        if orders > 0 {
            ordersNumberBtn?.setTitle("\(orders)", for: .normal)
        }
        
        // ship date
        if let dateString = order?.preferredShipDate, let date = dateString.dateWithFormat(DateFormat.iso8601) {
            shipDateBtn?.setTitle(date.stringWithFormat(DateFormat.EEEEMMMMddyyyy), for: .normal)
        } else {
            let normalDefaultDate = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 + 24*60*60*5) )
            shipDateBtn?.setTitle(normalDefaultDate.stringWithFormat(DateFormat.EEEEMMMMddyyyy), for: .normal)
        }
        
        // notes
        self.receiverNotes?.text = order?.notes

        // toggle with shoes
        toggleWithShoesBox?.backgroundColor = (order?.withShoes ?? false) ? Toggle.selected.color : Toggle.unselected.color
    }

    func startOrderSubmissionPrompts() {
        let cancelAA = UIAlertAction(title: "CCancel".localized(), style: .destructive)
        let okAA = UIAlertAction(title: "OSubmitButton".localized(), style: .default) { (_) in
            if let order = AuthenticationManager.currentPatient?.activeOrder() {
                OrderSubmissionManager.sharedManager.submitOrderInBackground(order)
            }
        }

        UIAlertController.showAlert(title: "OOrderSubmissionPromptTitle".localized(),
                                    message: "OOrderSubmissionPromptMessage".localized(),
                                    actions: [okAA, cancelAA], from: self)
    }
}

//MARK: - UITextViewDelegate

extension ShortOrderInfoViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        AuthenticationManager.currentPatient?.activeOrder().notes = textView.text
    }

}

// MARK:- Notifications

extension ShortOrderInfoViewController {

    @objc func orderSubmissionDidStart(_ notification: Notification) {
        DispatchQueue.main.async {
            SVProgressHUD.show(withStatus: "OSubmittingOrder".localized())
        }
    }

    @objc func orderSubmissionProgress(_ notification: Notification) {
        DispatchQueue.main.async {
            let progress = ((notification.userInfo?[OrderSubmissionProgressPercentageKey] as AnyObject).floatValue)
            SVProgressHUD.showProgress(progress!,
                                       status: "OUploadingFiles".localized())
        }
    }

    @objc func orderSubmissionDidFail(_ notification: Notification) {
        SVProgressHUD.dismiss()


        let message: String = (NetworkReachabilityManager()?.isReachable ?? false) ? "OSubmittingOrderErrorGenericMessage".localized() : "OSubmittingOrderErrorCheckInternetMessage".localized()

        let okAA = UIAlertAction(title: "COk", style: .default)
        UIAlertController.showAlert(title: "OSubmittingOrderErrorTitle".localized(),
                                    message: message,
                                    actions: [okAA], from: self)
    }

    @objc func orderSubmissionDidSucceed(_ notification: Notification) {
        SVProgressHUD.dismiss()
    }

}

extension ShortOrderInfoViewController: SimpleListViewControllerDelegate {
    func simpleListViewController(_ controller: SimpleListViewController, didSelectItem item: SimpleListItem) {
        let id = (controller.controllerId as NSString).integerValue
        let index = controller.items.index(where:{$0.cellDisplayText == item.cellDisplayText}) ?? 0
        let order = AuthenticationManager.currentPatient?.activeOrder()

        switch id {
        case 1:
            shippintTypeBtn?.setTitle(item.cellDisplayText, for: .normal)
            let order = AuthenticationManager.currentPatient?.activeOrder()
            order?.deliveryPreferenceType = DeliveryPrefereceType.allCases[index].rawValue

        case 4:
            daysNumberBtn?.setTitle(item.cellDisplayText, for: .normal)
            let num = (item.cellDisplayText as NSString).integerValue
            order?.numberOfDaysToWait = num
        case 5:
            ordersNumberBtn?.setTitle(item.cellDisplayText, for: .normal)
            let num = (item.cellDisplayText as NSString).integerValue
            order?.numberOfOrdersToWait = num
        case 2:
            shippingPreferenceBtn?.setTitle(item.cellDisplayText, for: .normal)
            order?.shippingPreferenceType = ShippingPrefereceType.allCases[index].rawValue

            switch index {
            case 0:
                dateSelectingView?.isHidden = true
                daysOrdersSelectingView?.isHidden = true
            case 1:
                dateSelectingView?.isHidden = true
                daysOrdersSelectingView?.isHidden = false
            case 2:
                dateSelectingView?.isHidden = false
                daysOrdersSelectingView?.isHidden = true
            default:break
            }
        default:break
        }

        OGDatabaseManager.save(order)

        controller.dismiss(animated: false)
    }
}
