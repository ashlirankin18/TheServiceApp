//
//  OrderSummaryAndPaymentViewController.swift
//  Stylist
//
//  Created by Ashli Rankin on 4/23/19.
//  Copyright © 2019 Ashli Rankin. All rights reserved.
//

import UIKit
import Cosmos

class OrderSummaryAndPaymentViewController: UITableViewController {
  @IBOutlet weak var confirmPayment: UIButton!
  @IBOutlet weak var servicesCollectionView: UICollectionView!
  @IBOutlet weak var ratingView: CosmosView!
  @IBOutlet weak var reviewTextview: UITextView!
  @IBOutlet weak var CardImage: UIButton!
  @IBOutlet weak var cardNumberCell: UITableViewCell!
  @IBOutlet weak var priceCell: UITableViewCell!
  
  @IBOutlet var tipButtons: [RoundedTextButton]!
  
 
  
  var userRating = Double()
  let ratingSettings = CosmosSettings()
  var localReviews = [String:Any]()
  let authService = AuthService()
  let cardImageArray = CardImages.AllCases()
  var providerId = ""{
    didSet{
     getAppointmentInfo(serviceProviderId: providerId)
    }
  }
  var appointment: Appointments?{
    didSet{
      servicesCollectionView.reloadData()
    }
  }
  var priceArray = [Int]() {
    didSet{
      priceCell.textLabel?.text = "Total"
      priceCell.detailTextLabel?.text = "$\(priceArray.reduce(0,+))"
     tableView.reloadData()
      
    }
  }
  let documentId = DBService.generateDocumentId
  var localInformation = [String:Any]()
  
  override func viewDidLoad(){
        super.viewDidLoad()
      servicesCollectionView.dataSource = self
      setUpCosmosView()
      getCardInformation()
      setUpNavBar()
   
    }

  @IBAction func tipButtonPressed(_ sender: RoundedTextButton) {
    if sender.isSelected {
      sender.buttonSelectedUI()
      sender.isSelected = false
    }else{
      sender.buttonDeselectedUI()
      sender.isSelected = true
    }
    guard let title = sender.currentTitle else {return}
    switch title {
    case "10%":
      let copyArray = priceArray
      let total = copyArray.reduce(0,+)
      let tip = 0.10
      let something = Double(total) * tip
      let grandTotal = something + Double(total)
      priceCell.detailTextLabel?.text = "$\(grandTotal)"
      
    case "15%":
      let copyArray = priceArray
      let total = copyArray.reduce(0,+)
      let tip = 0.15
      let something = Double(total) * tip
      let grandTotal = something + Double(total)
      priceCell.detailTextLabel?.text = "$\(grandTotal)"
    case "25%":
      let copyArray = priceArray
      let total = copyArray.reduce(0,+)
      let tip = 0.20
      let something = Double(total) * tip
      let grandTotal = something + Double(total)
      priceCell.detailTextLabel?.text = "$\(grandTotal)"
    case "Custom":
    let alertController = UIAlertController(title: "Tip", message: "Add Custom Tip", preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] (alert) in
      if let textEntered = alertController.textFields?.first?.text {
        guard let convertedTip = Double(textEntered) else {
          if sender.tag == 0 {
            sender.backgroundColor = .red
          }
          return
        }
       
        guard let copyArray = self?.priceArray else {return}
        let total = copyArray.reduce(0,+)
        let tip = convertedTip
        let something = Double(total) + tip
        let grandTotal = something
        self?.priceCell.detailTextLabel?.text = "$\(grandTotal)"
        
      }
    }
    alertController.addTextField { (textfield) in
      textfield.placeholder = "Enter custom tip"
      textfield.textAlignment = .center
      
    }
    alertController.addAction(cancelAction)
    alertController.addAction(submitAction )
      self.present(alertController, animated: true)
    default:
      print("default")
    }
  }
  
  func setUpNavBar(){
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(backButtonPressed))
    title = "Service Summary"
    
  }
  
  @objc func backButtonPressed(){
    dismiss(animated: true, completion: nil)
  }
  @IBAction func editButtonPressed(_ sender: UIButton) {
    
   guard let wallet = UIStoryboard(name: "Payments", bundle: nil).instantiateViewController(withIdentifier: "WalletViewController") as? WalletTableViewController else {
      print("no payment view controller found")
      return
    }
    let navController = UINavigationController(rootViewController: wallet)
    wallet.modalTransitionStyle = .coverVertical
    wallet.modalPresentationStyle = .currentContext
    present(navController, animated: true, completion: nil)
    
  }
  
  @IBAction func supportButtonPressed(_ sender: UIButton) {
    
    
    
  }
  
  @IBAction func confirmButtonPressed(_ sender: UIButton) {
    guard let currentUser = authService.getCurrentUser() else {return}
    localInformation["userId"] = currentUser.uid
    localInformation["providerId"] = providerId
    localInformation["total"] = priceCell.detailTextLabel?.text
    localInformation["documentId"] = documentId
    
    localReviews =  ["reviewerId":currentUser.uid,
                                   "providerId":providerId,
                                   "description" : reviewTextview.text ?? " " ,
                                    "createdDate":Date.getISOTimestamp(),
                                    "reviewId": documentId,
                                    "value" : userRating]
    sendPaymentInfoToDatabase(userId: currentUser.uid, information: localInformation, documentId: documentId)
    createUserReview(providerId: providerId, information: localReviews, userId: currentUser.uid)
  }
  
  
  
  
func setUpCosmosView(){
    ratingView.settings.fillMode = .half
    ratingView.rating = 5
    ratingView.didFinishTouchingCosmos = { captureRating in
      self.userRating = captureRating
      
  }
  }
func createUserReview(providerId:String,information:[String:Any],userId:String){
      
DBService.firestoreDB.collection(ServiceSideUserCollectionKeys.serviceProvider).document(providerId).collection(ReviewsCollectionKeys.reviews).document(documentId).setData(information) { [weak self](error) in
        if let error = error {
          self?.showAlert(title: "Error", message: "There was an error posting you review:\(error.localizedDescription)", actionTitle: "TryAgain")
        }
        
      }
      
      
    }
    
func getAppointmentInfo(serviceProviderId:String) {
      guard let currentUser = authService.getCurrentUser() else {
        showAlert(title: "Error", message: "No user signedIn", actionTitle: "TryAgain")
        return
      }
      DBService.firestoreDB.collection("bookedAppointments")
        .whereField("providerId", isEqualTo: providerId).whereField("userId", isEqualTo: currentUser.uid).getDocuments { [weak self] (snapshot, error) in
          
          if let error = error {
            
            self?.showAlert(title: "Error", message: "Could not retrieve appointments:\(error.localizedDescription)", actionTitle: "Try Again")
          }
          else if let snapshot = snapshot {
            
            if let appointmentData =  snapshot.documents.first?.data(){
             let appointment = Appointments(dict: appointmentData)
              self?.appointment = appointment
            }
            
          }
      }
    }
  func sendPaymentInfoToDatabase(userId:String,information:[String:Any],documentId:String){
    DBService.firestoreDB.collection(StylistsUserCollectionKeys.stylistUser).document(userId).collection("payments").document(documentId).setData(information) { (error) in
      if let error = error {
          self.showAlert(title: "Error", message: "Something went wrong while trying to process your payment:\(error.localizedDescription)", actionTitle: "Try Again")
      }
    }
    
    self.showAlert(title: "Sucess", message: "Your payment was sucessfully sent", style: .alert) { (okAction) in
      
    self.dismiss(animated: true, completion: nil)
    }
    
  }
  func getCardImage(cardType:String) -> UIImage? {
    switch cardType{
    case "Amex":
      return #imageLiteral(resourceName: "credit-card")
    case "ApplePay":
      return #imageLiteral(resourceName: "apple.png")
    case "Discover":
      return #imageLiteral(resourceName: "discover")
    case "MasterCard":
      return #imageLiteral(resourceName: "shop (1)")
    case "UnionPay":
      return #imageLiteral(resourceName: "pay")
    case "Visa":
     return #imageLiteral(resourceName: "charge")
    default:
      return #imageLiteral(resourceName: "card")
    }
  }
  func getCardInformation(){
    
    guard let currentUser = authService.getCurrentUser() else {return}
    DBService.firestoreDB.collection(StylistsUserCollectionKeys.stylistUser)
      .document(currentUser.uid)
      .collection("wallet")
      .getDocuments { [weak self] (snapshot, error) in
        if let error = error {
          self?.showAlert(title: "Error", message: "There was an error:\(error.localizedDescription)", actionTitle: "Try Again")
        }
        else if let snapshot = snapshot {
          guard let snapshotData =  snapshot.documents.first?.data() else { return }
          let savedCard = WalletModel(dict: snapshotData)
          self?.CardImage.setImage(self?.getCardImage(cardType: savedCard.cardType), for: .normal)
          self?.cardNumberCell.textLabel?.text = "Card Number"
          self?.cardNumberCell.textLabel?.textColor = .lightGray
          self?.cardNumberCell.detailTextLabel?.text = self?.returnCodedCardNumber(cardNumber: savedCard.cardNumber)
          self?.localInformation["cardType"] = savedCard.cardType
          self?.localInformation["cardNumber"] = savedCard.cardNumber
          
          
        }
    }
    
  }
  func returnCodedCardNumber(cardNumber:String) -> String{
   
    var cardArray = Array(cardNumber)
    
    cardArray.replaceSubrange(0...12, with: repeatElement("X", count: 12))
    cardArray.insert("-", at: 4)
    cardArray.insert("-", at: 9)
    cardArray.insert("-", at: 14)
    return String(cardArray)
  }
  
  }
  

extension OrderSummaryAndPaymentViewController:UICollectionViewDataSource{
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let appointment = appointment {
      return appointment.services.count
    }else {
      return 0
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SummaryCell", for: indexPath) as? SummaryServicesCollectionViewCell ,
      let appointment = appointment else {fatalError("no summary cell found")}
    
    let service = appointment.services[indexPath.row]
    localInformation["services"] = appointment.services
    let prices = appointment.prices[indexPath.row]
    cell.serviceDetails.text = "\(service)"
    cell.priceLabel.text = "$\(prices)"
    if let prices = Int(prices) {
      priceArray.append(prices)
    }
    return cell
  }
}
