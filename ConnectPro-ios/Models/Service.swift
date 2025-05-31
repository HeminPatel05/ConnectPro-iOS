import SwiftUI
import Firebase
import FirebaseFirestore

struct Service: Identifiable {
    var id: String // Kept as var instead of let
    let name: String
    let rating: Double
    let price: String
    let image: String
    let imageUrl: String?
    let description: String?
    let categoryId: String
    let isActive: Bool
    let providerUserId: String? // Keeping the providerUserId field
    
    // Added timing fields
    let startTime: Date?
    let endTime: Date?
    let workDays: [Int]?
    
    init(id: String, name: String, rating: Double, price: String, image: String, imageUrl: String? = nil,
         description: String? = nil, categoryId: String = "", isActive: Bool = true,
         providerUserId: String? = nil, startTime: Date? = nil, endTime: Date? = nil, workDays: [Int]? = nil) {
        self.id = id
        self.name = name
        self.rating = rating
        self.price = price
        self.image = image
        self.imageUrl = imageUrl
        self.description = description
        self.categoryId = categoryId
        self.isActive = isActive
        self.providerUserId = providerUserId
        
        // Initialize timing fields
        self.startTime = startTime
        self.endTime = endTime
        self.workDays = workDays
    }
    
    // Initialize from Firestore document
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        // Use document.documentID as the id instead of trying to get it from data
        self.id = document.documentID
        
        guard let name = data["name"] as? String,
              let rating = data["rating"] as? Double,
              let price = data["price"] as? String else {
            return nil
        }
        
        self.name = name
        self.rating = rating
        self.price = price
        self.image = data["image"] as? String ?? ""
        self.imageUrl = data["imageUrl"] as? String
        self.description = data["description"] as? String
        self.categoryId = data["categoryId"] as? String ?? ""
        self.isActive = data["isActive"] as? Bool ?? true
        self.providerUserId = data["providerUserId"] as? String
        
        // Read timing data from Firestore document
        if let startTimeTimestamp = data["startTime"] as? Timestamp {
            self.startTime = startTimeTimestamp.dateValue()
        } else {
            self.startTime = nil
        }
        
        if let endTimeTimestamp = data["endTime"] as? Timestamp {
            self.endTime = endTimeTimestamp.dateValue()
        } else {
            self.endTime = nil
        }
        
        self.workDays = data["workDays"] as? [Int]
    }
}


