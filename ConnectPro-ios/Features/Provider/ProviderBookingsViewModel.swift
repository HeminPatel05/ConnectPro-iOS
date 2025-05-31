//
//  ProviderBookingsViewModel.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/24/25.
//
import SwiftUI
import FirebaseAuth
import Firebase

class ProviderBookingsViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var isLoading = false
    @Published var statusFilter: BookingStatus? = nil
    
    private let db = Firestore.firestore()
    
    var filteredBookings: [Booking] {
        if let filter = statusFilter {
            return bookings.filter { $0.status == filter }
        } else {
            return bookings // When nil, return all bookings
        }
    }
    
    func loadBookings() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User ID is nil, not loading bookings")
            return
        }
        print("Loading bookings for user ID: \(userId)")
        
        isLoading = true
        
        db.collection("bookings")
            .whereField("providerUserId", isEqualTo: userId)
            .getDocuments(source: .default) { (snapshot, error) in
                self.isLoading = false
                
                if let error = error {
                    print("Error loading bookings: \(error.localizedDescription)")
                    return
                }
                
                print("Received snapshot with \(snapshot?.documents.count ?? 0) documents")
                
                guard let documents = snapshot?.documents else {
                    self.bookings = []
                    return
                }
                
                let fetchedBookings = documents.compactMap { document -> Booking? in
                    print("Attempting to create Booking from document: \(document.documentID)")
                    let booking = Booking(document: document)
                    print("Booking creation result: \(booking != nil ? "success" : "failed")")
                    return booking
                }
                print("Final fetched bookings count: \(fetchedBookings.count)")
                
                DispatchQueue.main.async {
                    self.bookings = fetchedBookings
                    print("Updated bookings array, now contains \(self.bookings.count) items")
                    print("Filtered bookings: \(self.filteredBookings.count) items")
                    self.objectWillChange.send()
                }
            }
    }
    
    func updateBookingStatus(_ booking: Booking, _ newStatus: BookingStatus) {
        db.collection("bookings").document(booking.id).updateData([
            "status": newStatus.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            if let error = error {
                print("Error updating booking status: \(error.localizedDescription)")
                return
            }
            
            // If the status is being set to completed, check if provider has > 10 completed bookings
            if newStatus == .completed {
                self?.checkAndUpdatePopularStatus(for: booking.serviceId, providerUserId: booking.providerUserId)
            }
            
            self?.loadBookings()
        }
    }

    // Add this new function to check completed bookings count and update isPopular
    private func checkAndUpdatePopularStatus(for serviceId: String, providerUserId: String) {
        db.collection("bookings")
            .whereField("providerUserId", isEqualTo: providerUserId)
            .whereField("status", isEqualTo: BookingStatus.completed.rawValue)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error checking completed bookings: \(error.localizedDescription)")
                    return
                }
                
                guard let count = snapshot?.documents.count else { return }
                print("Provider has \(count) completed bookings")
                
                // If more than 10 completed bookings, update service to be popular
                if count > 10 {
                    self?.db.collection("services").document(serviceId).updateData([
                        "isPopular": true
                    ]) { error in
                        if let error = error {
                            print("Error updating service popularity: \(error.localizedDescription)")
                        } else {
                            print("Service marked as popular successfully")
                        }
                    }
                }
            }
    }
}
