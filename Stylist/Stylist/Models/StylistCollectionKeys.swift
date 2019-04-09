//
//  StylistCollectionKeys.swift
//  Stylist
//
//  Created by Ashli Rankin on 4/3/19.
//  Copyright © 2019 Ashli Rankin. All rights reserved.
//

import Foundation

struct ServiceSideUserCollectionKeys{
  static let serviceProvider = "serviceProvider"
  static let userId = "userId"
  static let firstName = "firstName"
  static let lastName = "lastName"
  static let email = "email"
  static let joinedDate = "joinedDate"
  static let gender = "gender"
  static let isCertified = "isCertified"
  static let imageURL = "imageURL"
  static let bio = "bio"
  static let licenseNumber = "licenseNumber"
  static let licenseExpiryDate = "licenseExpiryDate"
  static let type = "type"
}

struct StylistsUserCollectionKeys{
  static let stylistUser = "stylistUser"
  static let userId = "userId"
  static let firstName = "firstName"
  static let lastName = "lastName"
  static let email = "email"
  static let gender = "gender"
  static let address = "address"
 static let imageURL = "imageURL"
  static let joinedDate = "joinedDate"
   static let type = "type"
}

struct RatingsCollectionKeys {
    static let ratings = "ratings"
    static  let ratingId = "ratingId"
    static let value = "value"
    static let userId = "userId"
  
}

struct ReviewsCollectionKeys{
 static let reviews = "reviews"
  static let reviewerId = "reviewrId"
  static let ratings = "ratings"
  static let description = "description"
  static let createdDate = "createdDate"
  
}

struct AvalibilityCollectionKeys{
  static let avalibility = "avalibility"
  static let userId = "userId"
  static let avalibilityId = "avalibility"
  static let dayName = "dayName"
  static let createdDate = "createdDate"
  static let days = "days"
}

struct DaysCollectionKeys{
  static let days = "days"
  static let userId = "userId"
  static let avalibliehours = "avalibleHours"
  static let daysId = "daysId"
}