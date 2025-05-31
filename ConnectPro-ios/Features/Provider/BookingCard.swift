import SwiftUI
import Firebase
import FirebaseFirestore
import UIKit

// Booking Card Component
struct BookingCard: View {
    let booking: Booking
    let updateBookingStatus: (Booking, BookingStatus) -> Void
    @State private var showActionSheet = false
    @State private var userName: String = "Loading..."
    @State private var priceString: String = "$0.00"
    @State private var userEmail: String = ""
    @State private var addressDetails: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(booking.serviceName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(userName)
                        .font(.subheadline)
                }
                
                Spacer()
                
                StatusBadge(status: booking.status)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label {
                        Text(formatDate(booking.date))
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                    }
                    
                    Label {
                        Text(formatTime(booking.date))
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Text("\(priceString)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Display service address
            if !addressDetails.isEmpty {
                Divider()
                
                Label {
                    Text(addressDetails)
                        .font(.subheadline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
            
            HStack {
                Button(action: {
                    showActionSheet = true
                }) {
                    Text("Update Status")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    if !userEmail.isEmpty {
                        if let url = URL(string: "mailto:\(userEmail)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }) {
                    Text("Contact")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("Update Booking Status"),
                message: Text("Select a new status for this booking"),
                buttons: [
                    .default(Text("Pending")) {
                        updateBookingStatus(booking, .pending)
                    },
                    .default(Text("Confirm")) {
                        updateBookingStatus(booking, .confirmed)
                    },
                    .default(Text("Complete")) {
                        updateBookingStatus(booking, .completed)
                    },
                    .destructive(Text("Cancel Booking")) {
                        updateBookingStatus(booking, .cancelled)
                    },
                    .cancel()
                ]
            )
        }
        .onAppear {
            fetchUserName()
            fetchPrice()
            fetchAddressDetails()
        }
    }
    
    private func fetchUserName() {
        let db = Firestore.firestore()
        db.collection("userData").document(booking.userId).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                if let firstName = document.data()?["fullName"] as? String {
                    DispatchQueue.main.async {
                        self.userName = "\(firstName)"
                    }
                }
                
                if let email = document.data()?["email"] as? String {
                    DispatchQueue.main.async {
                        self.userEmail = email
                    }
                }
            }
        }
    }
    
    private func fetchPrice() {
        // If booking.price exists and is a String, use it
        if let price = booking.price as? String, !price.isEmpty {
            self.priceString = price
            return
        }
        
        // Otherwise, fetch the price from the service
        let db = Firestore.firestore()
        db.collection("services").document(booking.serviceId).getDocument { document, error in
            if let error = error {
                print("Error fetching service price: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                if let price = document.data()?["price"] as? String {
                    DispatchQueue.main.async {
                        self.priceString = price
                        print("Fetched price: \(price)")
                    }
                }
            }
        }
    }
    
    private func fetchAddressDetails() {
        // First try to get address from booking.addressDetails
        if let addressDetails = booking.addressDetails as? [String: Any] {
            if let address = addressDetails["address"] as? String,
               let city = addressDetails["city"] as? String,
               let state = addressDetails["state"] as? String,
               let zipCode = addressDetails["zipCode"] as? String {
                self.addressDetails = "\(address), \(city), \(state) \(zipCode)"
                return
            }
        }
        
        // If no address in booking, try to fetch from addressId
        if let addressId = booking.addressId {
            let db = Firestore.firestore()
            db.collection("userData").document(booking.userId).collection("addresses").document(addressId).getDocument { document, error in
                if let error = error {
                    print("Error fetching address: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists, let data = document.data() {
                    if let address = data["address"] as? String,
                       let city = data["city"] as? String,
                       let state = data["state"] as? String,
                       let zipCode = data["zipCode"] as? String {
                        DispatchQueue.main.async {
                            self.addressDetails = "\(address), \(city), \(state) \(zipCode)"
                        }
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
