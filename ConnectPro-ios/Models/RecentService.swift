import SwiftUI
import FirebaseFirestore

struct RecentService: Identifiable {
    let id: Int
    let name: String
    let serviceId: String
    let lastViewed: Date
    
    var lastViewedFormatted: String {
        // Create a formatter that shows relative time (e.g., "2 hours ago")
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastViewed, relativeTo: Date())
    }
    
    init?(document: QueryDocumentSnapshot) {
        print("🔎 Parsing document: \(document.documentID)")
        print("🔎 Document data: \(document.data())")
        
        // Handle ID - Generate a numeric ID regardless of original format
        if let idInt = document.data()["id"] as? Int {
            self.id = idInt
        } else if let idString = document.data()["id"] as? String, let idInt = Int(idString) {
            self.id = idInt
        } else {
            // Generate a hash from the document ID if needed
            print("⚠️ Creating hash ID from document ID: \(document.documentID)")
            self.id = abs(document.documentID.hashValue) % 10000
        }
        
        // Get service name with fallback
        if let name = document.data()["name"] as? String {
            self.name = name
        } else {
            print("⚠️ Missing name, using fallback")
            self.name = "Unknown Service"
        }
        
        // Get serviceId (use document ID as fallback)
        if let serviceId = document.data()["serviceId"] as? String {
            self.serviceId = serviceId
        } else {
            print("⚠️ Using document ID as serviceId: \(document.documentID)")
            self.serviceId = document.documentID
        }
        
        // Parse timestamp with proper fallback
        if let timestamp = document.data()["lastViewed"] as? Timestamp {
            self.lastViewed = timestamp.dateValue()
        } else if let lastViewedDate = document.data()["lastViewed"] as? Date {
            self.lastViewed = lastViewedDate
        } else {
            print("⚠️ No timestamp found, using current date")
            self.lastViewed = Date()
        }
        
        print("✅ Successfully parsed RecentService: \(name) (ID: \(id), lastViewed: \(lastViewed))")
    }
}
