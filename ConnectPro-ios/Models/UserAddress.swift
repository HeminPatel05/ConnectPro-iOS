//
//  UserAddress.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/25/25.
//


// Updated UserAddress model to match the Firebase structure you showed
struct UserAddress: Identifiable {
    let id: String
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let isPrimary: Bool
    
    var fullAddress: String {
        return "\(address), \(city), \(state) \(zipCode)"
    }
    
    // Create from Firestore data
    init?(id: String, data: [String: Any]) {
        guard let address = data["address"] as? String,
              let city = data["city"] as? String,
              let state = data["state"] as? String,
              let zipCode = data["zipCode"] as? String else {
            return nil
        }
        
        self.id = id
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.isPrimary = data["isPrimary"] as? Bool ?? false
    }
}