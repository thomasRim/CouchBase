//
//  PatientsMasterViewController.swift
//  OG Intake
//
//  Created by Vladimir Yevdokimov on 09.12.2019.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import FontAwesomeKit

class PatientsMasterViewController : UIViewController {

    // UI
    @IBOutlet weak fileprivate var tableView: UITableView?
    @IBOutlet weak fileprivate var clinicSelectBtn: UIButton?
    @IBOutlet weak fileprivate var patientBarView: UIView?
    @IBOutlet weak fileprivate var editPatientsBtn: UIButton?
    @IBOutlet weak fileprivate var addNewPatientBtn: UIButton?

    // Vars
//    private var detailViewController: ClinicDetailViewController?
    private var searchBar: UISearchBar?
    private var appDelegate: AppDelegate?
    private var inEditMode: Bool = false
    var patients = [OGPatient]()

    private let refreshControl = UIRefreshControl()

    // Functions
    override func awakeFromNib() {
        super.awakeFromNib()
        self.preferredContentSize = CGSize(width: 320, height: 600)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.isHidden = true
        self.patientBarView?.isHidden = true

        self.searchBar = UISearchBar()
        self.searchBar?.delegate = self
        
        self.tableView?.tableHeaderView = self.searchBar;
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = refreshControl
        } else {
            tableView?.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(loadPatients), for: .valueChanged)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView?.reloadData()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier
        switch identifier {
        case "showPatientInfo":
            let vc = segue.destination as? PatientEditViewController
            vc?.patient = AuthenticationManager.currentPatient
            vc?.delegate = self
        case "showClinicDetail":
            let vc = (segue.destination as? UINavigationController)?.topViewController as? ClinicDetailViewController
            vc?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem;
            vc?.navigationItem.leftItemsSupplementBackButton = true;
        case "showPatientAdd":
            let vc = segue.destination as? PatientNewViewController
            vc?.delegate = self
        case "showClinicAdd":
            let vc = segue.destination as? ClinicNewEditViewController
            vc?.delegate = self
        default:break
        }
    }

    //MARK: - Outlet Actions

    @IBAction fileprivate func insertNewObject(WithSender sender: UIButton?) {
        if AuthenticationManager.currentClinic != nil {
            self.performSegue(withIdentifier: "showPatientAdd", sender: nil)
        } else {
            UIAlertController.showAlert(title: "Warning", message: "You should select clinic first to be able to add new patient", from: self)
        }
    }

    @IBAction fileprivate func selectClinicTap(WithSender sender: UIButton?) {
        let lvc = SimpleListViewController()
        lvc.delegate = self;
        lvc.items = OGDatabaseManager.allClinics(for: AuthenticationManager.currentPractitioner)
        lvc.modalPresentationStyle = .popover
        lvc.preferredContentSize = CGSize(width: 300, height: 400)

        let popover = lvc.popoverPresentationController
        popover?.sourceView = self.view;
        popover?.sourceRect = sender?.frame ?? .zero;

        present(lvc, animated: true)
    }

    @IBAction fileprivate func togglePatientsEdit(WithSender sender: UIButton?) {
        if inEditMode == true {
            editPatientsBtn?.setTitle("Edit", for: .normal)
            tableView?.setEditing(false, animated: true)
        } else {
            editPatientsBtn?.setTitle("  Cancel ", for: .normal)
            tableView?.setEditing(true, animated: true)
        }
        inEditMode = !inEditMode
        self.loadPatients()
    }
    //MARK: - Other privates

    @IBAction fileprivate func loadPatients() {

        patients = OGDatabaseManager.allPatients(for: AuthenticationManager.currentClinic)

        if let searchText = searchBar?.text, searchText.count > 0 {
            patients = patients.filter{$0.firstName.contains(searchText) || $0.lastName.contains(searchText)}
        }

        tableView?.reloadData()
        refreshControl.endRefreshing()
    }

    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(orderSubmissionDidSucceed(_:)), name: .orderSubmissionDidSucceed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authLoginSuccessful(_:)), name: .authLoginSuccessful, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authLoginSuccessful(_:)), name: .authLoginSuccessful, object: nil)
    }

    func popToRootAndRefresh() {
        let masterNC = self.splitViewController?.viewControllers[0] as? UINavigationController
        masterNC?.popToRootViewController(animated: true)

        let detailNC = self.splitViewController?.viewControllers[1] as? UINavigationController
        detailNC?.popToRootViewController(animated: true)

        self.loadPatients()
    }

    func dismissAndRefresh() {
        self.dismiss(animated: true) { [weak self] in
            self?.loadPatients()
        }
    }

    @IBAction fileprivate func  orderSubmissionDidSucceed(_ notification: Notification) {

    }

    @IBAction fileprivate func authLoginSuccessful(_ notification: Notification) {

    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource
extension PatientsMasterViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return patients.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        self.configure(cell: cell, at: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    internal func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let patient = patients[indexPath.row]
            let cancelAction = UIAlertAction(title: "CCancel".localized(), style: .cancel, handler: nil)
            let proceedAction = UIAlertAction(title: "CDelete".localized(), style: .default) { (_) in
                DispatchQueue.main.async {
                    patient.delete()
//                    OGDatabaseManager.delete(patient)
                    self.loadPatients()
                }

            }
            UIAlertController.showAlert(title: "MDeletePatientAlertTitle".localized(),
                                        message: NSString(format: "MDeletePatientAlertMessage".localized() as NSString, patient.name()) as String, actions: [proceedAction, cancelAction], from: self)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let patient = patients[indexPath.row]
        AuthenticationManager.currentPatient = patient

        self.performSegue(withIdentifier: "showPatientInfo", sender: nil)

        // Details setup
        let detailNavController = self.splitViewController?.viewControllers[1] as? UINavigationController
        detailNavController?.popToRootViewController(animated: false)


        let orderTabBarController = UIStoryboard(name: "Order", bundle: nil).instantiateInitialViewController() as? OrderTabBarController
    orderTabBarController?.navigationController?.setNavigationBarHidden(true, animated: false)

        let  orderController = orderTabBarController?.viewControllers?[0] as? OrderScansViewController
        orderController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem;
        orderController?.navigationItem.leftItemsSupplementBackButton = true;
        orderController?.navigationController?.isNavigationBarHidden = false;

        orderTabBarController?.selectedViewController = orderController;

        if let vc = orderTabBarController {
            detailNavController?.pushViewController(vc, animated: false)
        }
    }

    func configure(cell:UITableViewCell, at indexPath: IndexPath) {
        let patient = patients[indexPath.row]
        cell.textLabel?.text = patient.name()
        if let order = patient.lastSubmittedOrder(), let dateString = order.submittedAt {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short

            cell.detailTextLabel?.text = "\("MLastOrder".localized()) \("MOrderOn".localized()) \(dateString)"
        } else {
            cell.detailTextLabel?.text = " "
        }
        let image = FAKIonIcons.personIcon(withSize: 64)?.image(with: CGSize(width: 64, height: 64))
        cell.imageView?.image = image
    }

}

//MARK: - PatientNewViewController
extension PatientsMasterViewController: PatientNewViewControllerDelegate {
    func patientNewViewController(_ controller: PatientNewViewController, didAddPatient patient: OGPatient) {
        self.dismissAndRefresh()
    }

    func patientNewViewControllerDidCancelEntry(_ controller: PatientNewViewController) {
        self.dismissAndRefresh()
    }
}

// MARK: - PatientEditViewControllerDelegate
extension PatientsMasterViewController: PatientEditViewControllerDelegate {
    func patientEditViewController(_ controller: PatientEditViewController, didUpdatePatient patient: OGPatient?) {
        popToRootAndRefresh()
    }
}

// MARK: - ClinicNewEditViewControllerDelegate
extension PatientsMasterViewController: ClinicNewEditViewControllerDelegate {

    func clinicNewEditViewController(_ controller: ClinicNewEditViewController, didAddClinic clinic: OGClinic) {
        controller.dismiss(animated: false, completion: { [weak self] in
            AuthenticationManager.switchClinic(clinic)
            self?.clinicSelectBtn?.setTitle("Clinic: \(clinic.name)", for: .normal)
            self?.clinicSelectBtn?.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            self?.tableView?.isHidden = false
            self?.patientBarView?.isHidden = false

            self?.loadPatients()
        })
    }

    func clinicNewEditViewController(_ controller: ClinicNewEditViewController, didUpdateClinic clinic: OGClinic) {
        controller.dismiss(animated: false, completion: nil)
    }

    func clinicNewEditViewControllerDidCancelEntry(_ controller: ClinicNewEditViewController) {
        controller.dismiss(animated: false, completion: nil)
    }
}

//MARK: - SimpleListViewControllerDelegate
extension PatientsMasterViewController: SimpleListViewControllerDelegate {
    func simpleListViewController(_ controller: SimpleListViewController, didSelectItem item: SimpleListItem) {
        controller.dismiss(animated: false) { [weak self] in
            if let clinic = item as? OGClinic {
                AuthenticationManager.switchClinic(clinic)
                self?.clinicSelectBtn?.setTitle("Clinic: \(clinic.name)", for: .normal)
                self?.clinicSelectBtn?.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                self?.tableView?.isHidden = false
                self?.patientBarView?.isHidden = false

                self?.loadPatients()
            }
        }
    }

    func simpleListViewControllerDidSelectAddNew(_ controller: SimpleListViewController) {
        controller.dismiss(animated: false) { [weak self] in
            self?.performSegue(withIdentifier: "showClinicAdd", sender: nil)
        }
    }
}

extension PatientsMasterViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        loadPatients()
    }
}
