//
//  DiscoverCollectionViewCell.swift
//  Stylist
//
//  Created by Oniel Rosario on 4/16/19.
//  Copyright © 2019 Ashli Rankin. All rights reserved.
//

import UIKit

class DiscoverCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var collectionViewImage: UIImageView!
    @IBOutlet weak var providerFullname: UILabel!
    @IBOutlet weak var providerJobTitle: UILabel!
    @IBOutlet weak var providerRating: UILabel!
    @IBOutlet weak var providerDistance: UILabel!
    @IBOutlet weak var goldStar: UIImageView!
    
    public func configureCell(provider: ServiceSideUser, favorites: [ServiceSideUser]) {
        setRating(provider: provider)
        providerFullname.text = "\(provider.firstName ?? "") \(provider.lastName ?? "")"
        providerJobTitle.text = provider.jobTitle
        collectionViewImage.kf.setImage(with: URL(string: provider.imageURL ?? ""), placeholder:#imageLiteral(resourceName: "placeholder.png") )
        switch provider.jobTitle {
        case "Barber":
            providerDistance.text = "2.9 Mi."
        case "Hair Stylist":
            providerDistance.text = "5.0 Mi."
        default:
            providerDistance.text = "3.25 Mi."
        }
        for favorite in favorites {
            if favorite.userId == provider.userId {
                goldStar.isHidden = false
                break
            } else {
                goldStar.isHidden = true
            }
        }
    }
    private func setRating(provider: ServiceSideUser){
        DBService.getReviews(provider: provider) { (reviews, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let reviews = reviews {
                let allRatingValues =   reviews.map{$0.value}
                guard !allRatingValues.isEmpty else {
                    self.providerRating.text = "No Ratings"
                    return
                }
                let total = allRatingValues.reduce(0, +)
                let avg = Double(total) / Double(allRatingValues.count)
                print(avg)
                self.providerRating.text = "\(avg)⭐️🍚"
            }
        }
    }
}
