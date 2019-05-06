//
//  ClientViewController.swift
//  Stylist
//
//  Created by Ashli Rankin on 4/5/19.
//  Copyright © 2019 Ashli Rankin. All rights reserved.
//
import UIKit
import Kingfisher
import Cosmos
import MessageUI
import FirebaseFirestore
import UserNotifications

private enum tableviewStatus: String {
    case upcoming = "upcoming"
    case history = "history"
}

class ClientProfileController: UIViewController {
    @IBOutlet weak var profileImageView: CircularImageView!
    @IBOutlet weak var clientFullNameLabel: UILabel!
    @IBOutlet weak var userRatingView: CosmosView!
    @IBOutlet weak var clientEmail: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bookingsButton: CircularButton!
    @IBOutlet weak var historyButton: CircularButton!
    @IBOutlet weak var switchButton: UIButton!
    var listener: ListenerRegistration!
    var statusListener: ListenerRegistration!
    let noBookingView = ProfileNoBooking(frame: CGRect(x: 0, y: 0, width: 394, height: 284))
    var isSwitched = false
    let authService = AuthService()
    var timer: Timer?
    private var tableviewStatus: tableviewStatus = .upcoming
    var appointments = [Appointments]() {
        didSet {
            tableviewStatus == .upcoming ? getUpcomingAppointments() : getPastAppointments()
            DBService.cancelPastBookedAppointments(appointments: appointments)
        }
    }
    var filterAppointments = [Appointments]() {
        didSet {
            fetchProviders()
        }
    }
    var filterProviders = [ServiceSideUser]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    var checkForProvider = [ServiceSideUser]()
    private var stylistUser: StylistsUser? {
        didSet {
            DispatchQueue.main.async {
                self.updateUI()
                self.getAllAppointments(id: self.stylistUser!.userId)
                DBService.getProviders(completionHandler: { (providers, error) in
                    guard let currentuser = self.authService.getCurrentUser() else {
                        return
                    }
                    if let error = error {
                        print(error)
                    } else if let providers = providers {
                       self.checkForProvider = providers.filter({ (provider) -> Bool in
                        return provider.userId == currentuser.uid
                        })
                    }
                    if self.checkForProvider.isEmpty {
                        self.switchButton.isHidden = true
                    } else  {
                        self.switchButton.isHidden = false
                    }
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = #colorLiteral(red: 0.2461647391, green: 0.3439296186, blue: 0.5816915631, alpha: 1)
        authService.authserviceSignOutDelegate = self
        setupTableView()
        getUpcomingAppointments()
    }
    
  
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(reloadAppointments), userInfo: nil, repeats: true)
        fetchCurrentUser()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        timer?.invalidate()
    }
    
    // MARK: Initial Setup
    private func fetchCurrentUser() {
        guard let currentUser = AuthService().getCurrentUser() else {
            showAlert(title: "No User Login", message: nil, actionTitle: "Ok")
            return
        }
        DBService.getDatabaseUser(userID: currentUser.uid) { (error, stylistUser) in
            if let error = error {
                self.showAlert(title: "Error fetching account info", message: error.localizedDescription, actionTitle: "OK")
            } else if let stylistUser = stylistUser {
                self.stylistUser = stylistUser
            }
        }
    }
    
    private func updateUI() {
        guard let user = stylistUser else { return }
        if let imageUrl = user.imageURL {
            profileImageView.kf.indicatorType = .activity
            profileImageView.kf.setImage(with: URL(string: imageUrl), placeholder: #imageLiteral(resourceName: "placeholder.png"))
        }
        clientFullNameLabel.text = user.fullName
        clientFullNameLabel.textColor = .white
        clientEmail.textColor = .white
        clientEmail.text = user.email
        setStylistUserRating()
    }
    private func setStylistUserRating() {
        userRatingView.settings.updateOnTouch = false
        userRatingView.settings.fillMode = .precise
        userRatingView.rating = 5
    }
    
    private func setupTableView() {
        historyButton.layer.borderWidth = 5
        bookingsButton.layer.borderWidth = 5
        historyButton.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        bookingsButton.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layer.cornerRadius = 10
        tableView.backgroundColor = #colorLiteral(red: 0.1619916558, green: 0.224360168, blue: 0.3768204153, alpha: 1)
        tableView.tableFooterView = UIView()
        tableView.layer.cornerRadius = 10
        setupTableviewBackground()
    }
    private func setupTableviewBackground() {
        tableView.backgroundColor = .clear
        tableView.backgroundView = noBookingView
    }
    
    private func getAllAppointments(id: String) {
        DBService.getBookedAppointments(userId: id) { [weak self] (error, appointments) in
            if let error = error {
                self?.showAlert(title: "Error Fetching User Appointments", message: error.localizedDescription, actionTitle: "Ok")
            } else if let appointments = appointments {
                self?.appointments = appointments
            }
        }
    }

    private func fetchProviders() {
        var filterProviders = [ServiceSideUser]()
        if filterAppointments.count == 0 { self.filterProviders = filterProviders }
        for appointment in filterAppointments {
            DBService.getProviderFromAppointment(appointment: appointment) { (error, provider) in
                if let error = error {
                    self.showAlert(title: "Fetch Providers Error", message: error.localizedDescription, actionTitle: "Ok")
                } else if let provider = provider {
                    filterProviders.append(provider)
                    if filterProviders.count == self.filterAppointments.count {
                        self.filterProviders = filterProviders
                    }
                }
            }
        }
    }
    
    // MARK: Actions
    @IBAction func changeUserType(_ sender: UIButton) {
        isSwitched = !isSwitched
        if isSwitched {
            showProviderTab()
        }
    }
    private func showProviderTab() {
        let storyboard = UIStoryboard(name: "ServiceProvider", bundle: nil)
        guard let providerTab = storyboard.instantiateViewController(withIdentifier: "ServiceTabBar") as? ServiceProviderTabBar else {return}
        providerTab.modalTransitionStyle = .crossDissolve
        providerTab.modalPresentationStyle = .overFullScreen
        self.present(providerTab, animated: true)
    }
    
    @IBAction func toggleButtons(_ sender: CircularButton) {
        tableviewStatus = sender == bookingsButton ? .upcoming : .history
        reloadAppointments()
    }
    private func getUpcomingAppointments() {
        filterAppointments = appointments.filter { $0.status == "pending" || $0.status == "inProgress" }
        if filterAppointments.count == 0 {
            noBookingView.noBookingLabel.text = "No current appointments yet."
            tableView.backgroundView?.isHidden = false
        } else {
            tableView.backgroundView?.isHidden = true
        }
    }
    private func getPastAppointments() {
        filterAppointments = appointments.filter { $0.status == "canceled" || $0.status == "completed" }
        if filterAppointments.count == 0 {
            noBookingView.noBookingLabel.text = "No history appointments yet."
            tableView.backgroundView?.isHidden = false
        } else {
            tableView.backgroundView?.isHidden = true
        }
    }
    
    @IBAction func moreOptionsButtonPressed(_ sender: UIButton) {
        let actionTitles = ["Edit Profile", "Support", "Sign Out", "Join Stylists Providers"]
        
      showActionSheet(title: "Menu:\(ApplicationInfo.getVersionBuildNumber())", message: nil, actionTitles: actionTitles, handlers: [ { [weak self] editProfileAction in
            let storyBoard = UIStoryboard(name: "User", bundle: nil)
            guard let destinationVC = storyBoard.instantiateViewController(withIdentifier: "EditProfileVC") as? ClientEditProfileController else {
                fatalError("EditProfileVC is nil")
            }
            destinationVC.modalPresentationStyle = .currentContext
            if let currentUser = self?.stylistUser {
                destinationVC.stylistUser = currentUser
            } else {
                return
            }
            self?.present(UINavigationController(rootViewController: destinationVC), animated: true)
            
            }, { [weak self] supportAction in
                guard MFMailComposeViewController.canSendMail() else {
                    self?.showAlert(title: "This Device Can't send email", message: nil, actionTitle: "Ok")
                    return
                }
                let mailComposer = MFMailComposeViewController()
                mailComposer.mailComposeDelegate = self
                mailComposer.setToRecipients(["jiantingli@pursuit.org"])
                mailComposer.setSubject("\(self?.stylistUser?.fullName ?? "Guest"): Help Me!")
                mailComposer.setMessageBody("To: Customer Support, \n\n", isHTML: false)
                self?.present(mailComposer, animated: true)
                
            }, { [weak self] signOutAction in
                self?.authService.signOut()
                self?.presentLoginViewController()
            },{ [weak self] becomeProvider in
                print("provider sign up sheet")
            }
            ])
    }
    
    private func presentLoginViewController() {
        let window = (UIApplication.shared.delegate  as! AppDelegate).window
        guard let loginViewController = UIStoryboard(name: "Entrance", bundle: nil).instantiateViewController(withIdentifier: "LoginVC") as? LoginViewController else {return}
        loginViewController.modalPresentationStyle = .fullScreen
        loginViewController.modalTransitionStyle = .coverVertical
        window?.rootViewController = UINavigationController(rootViewController: loginViewController)
        window?.makeKeyAndVisible()
    }
    
    // MARK: Timer
    @objc private func reloadAppointments() {
        guard let user = stylistUser else { return }
        getAllAppointments(id: user.userId)
    }
}

extension ClientProfileController:AuthServiceSignOutDelegate{
    func didSignOutWithError(_ authservice: AuthService, error: Error) {
        showAlert(title: "Unable to SignOut", message: "There was an error signing you out:\(error.localizedDescription)", actionTitle: "Try Again")
    }

    func didSignOut(_ authservice: AuthService) {
        dismiss(animated: true, completion: nil)
    }
}

extension ClientProfileController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let error = error {
            self.showAlert(title: "Error Sending Email", message: error.localizedDescription, actionTitle: "Ok")
            controller.dismiss(animated: true)
        }
        switch result {
        case .cancelled:
            print("Cancelled")
        case .failed:
            self.showAlert(title: "Failed to send email", message: nil, actionTitle: "Ok")
        case .saved:
            print("Saved")
        case .sent:
            self.showAlert(title: "Email Sent", message: nil, actionTitle: "Ok")
        @unknown default:
            fatalError()
        }
        controller.dismiss(animated: true)
    }
}

extension ClientProfileController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterAppointments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! UserProfileTableViewCell
        let appointment = filterAppointments[indexPath.row]
        let provider = filterProviders[indexPath.row]
        cell.configuredCell(provider: provider, appointment: appointment)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "ServiceProvider", bundle: nil)
        guard let destinationVC = storyboard.instantiateViewController(withIdentifier:
            "ServiceDetailVC") as? ServiceDetailViewController else { return }
        destinationVC.modalTransitionStyle = .crossDissolve
        destinationVC.modalPresentationStyle = .overFullScreen
        let appointment = filterAppointments[indexPath.row]
        destinationVC.appointment = appointment
        destinationVC.status = appointment.status
        DBService.getProviderFromAppointment(appointment: appointment) { (error, provider) in
            if let error = error {
                self.showAlert(title: "Error Fetching Provider", message: error.localizedDescription, actionTitle: "Ok")
            } else if let provider = provider {
                destinationVC.provider = provider
                self.present(destinationVC, animated: true)
            }
        }
    }
}
