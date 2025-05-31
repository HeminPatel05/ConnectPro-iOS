import SwiftUI
import FirebaseFirestore
import FirebaseAuth

import SwiftUI

struct BookingsView: View {
    @StateObject private var viewModel = BookingsViewModel()
    @State private var selectedTab = BookingTab.upcoming
    @State private var isShowingFilter = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Booking Status", selection: $selectedTab) {
                    ForEach(BookingTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // Pending Only Toggle (show only when on Upcoming tab)
                if selectedTab == .upcoming {
                    Toggle("Show Pending Only", isOn: $viewModel.showPendingOnly)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // Bookings List
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                    } else if viewModel.bookingsForTab(selectedTab).isEmpty {
                        emptyStateView(for: selectedTab)
                    } else {
                        bookingsListView(for: selectedTab)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("My Bookings")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.fetchBookings()
            }
            .onAppear {
                viewModel.fetchBookings()
            }
        }
    }
    
    // MARK: - Booking List View
    private func bookingsListView(for tab: BookingTab) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.bookingsForTab(tab)) { booking in
                    BookingCardView(
                        booking: booking,
                        viewModel: viewModel,
                        onRebook: {
                            viewModel.rebookService(booking)
                        },
                        onCancel: {
                            viewModel.cancelBooking(booking)
                        },
                        onRate: { rating in
                            viewModel.rateBooking(booking, rating: rating)
                        }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Empty State View
    private func emptyStateView(for tab: BookingTab) -> some View {
        VStack(spacing: 24) {
            Image(systemName: emptyStateIcon(for: tab))
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.7))
                .padding()
            
            Text(emptyStateText(for: tab))
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if tab == .upcoming {
                Button(action: {
                    // Navigate to home or explore
                }) {
                    Text("Book a Service")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
            }
        }
        .padding(.horizontal, 40)
    }
    
    private func emptyStateIcon(for tab: BookingTab) -> String {
        switch tab {
        case .upcoming:
            return "calendar.badge.plus"
        case .completed:
            return "checkmark.circle"
        case .cancelled:
            return "xmark.circle"
        }
    }
    
    private func emptyStateText(for tab: BookingTab) -> String {
        switch tab {
        case .upcoming:
            return "You don't have any upcoming bookings.\nBook a service to get started!"
        case .completed:
            return "You don't have any completed bookings yet."
        case .cancelled:
            return "You don't have any cancelled bookings."
        }
    }
}




// MARK: - Status Badge
struct StatusBadge: View {
    let status: BookingStatus
    
    var body: some View {
        Text(status.displayText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(status.color.opacity(0.1))
            .cornerRadius(15)
    }
}


// MARK: - Enums & Models
enum BookingTab: String, CaseIterable {
    case upcoming, completed, cancelled
    
    var title: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .upcoming: return .green
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
    
    var description: String {
        switch self {
        case .upcoming: return "Pending, Confirmed & In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

enum BookingStatus: String, Codable {
    case pending, confirmed, inProgress, completed, cancelled
    
    var displayText: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .yellow
        case .confirmed: return .green
        case .inProgress: return .orange
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}

struct Booking: Identifiable {
    let id: String
    let userId: String
    let providerUserId: String
    let serviceId: String
    let serviceName: String
    let providerName: String?
    let serviceImageUrl: String?
    let date: Date
    let status: BookingStatus
    let price: String?
    let location: String?
    let rating: Int
    let notes: String?
    // New address fields
    let addressId: String?
    let addressDetails: [String: String]?
    let timeSlot: String
    
    // Initialize from Firestore document
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let userId = data["userId"] as? String,
              let providerUserId = data["providerUserId"] as? String,
              let serviceId = data["serviceId"] as? String,
              let serviceName = data["serviceName"] as? String,
              let statusRaw = data["status"] as? String,
              let timeSlot = data["timeSlot"] as? String, // Uncommented and added this check
              let status = BookingStatus(rawValue: statusRaw) else {
            return nil
        }
        
        // Handle different date formats
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let date: Date
        if let timestamp = data["date"] as? Timestamp {
            date = timestamp.dateValue()
        } else if let dateString = data["date"] as? String,
                  let parsedDate = dateFormatter.date(from: dateString) {
            date = parsedDate
        } else if let dateTimestamp = data["createdAt"] as? Timestamp {
            // Fallback to createdAt if date is missing
            date = dateTimestamp.dateValue()
        } else {
            // Could not parse date
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.providerUserId = providerUserId
        self.serviceId = serviceId
        self.serviceName = serviceName
        self.providerName = data["providerName"] as? String
        self.serviceImageUrl = data["serviceImageUrl"] as? String
        self.date = date
        self.status = status
        self.price = data["servicePrice"] as? String ?? data["price"] as? String
        self.location = data["location"] as? String
        self.rating = data["rating"] as? Int ?? 0
        self.notes = data["notes"] as? String
        self.addressId = data["addressId"] as? String
        self.addressDetails = data["addressDetails"] as? [String: String]
        self.timeSlot = timeSlot // Added this line to set the timeSlot property
    }
    
    // For preview and testing - also need to update this initializer
    init(id: String, userId: String, providerUserId: String, serviceId: String, serviceName: String, providerName: String? = nil,
         serviceImageUrl: String? = nil, date: Date, status: BookingStatus, price: String? = nil,
         location: String? = nil, rating: Int = 0, notes: String? = nil, addressId: String? = nil,
         addressDetails: [String: String]? = nil, timeSlot: String = "12:00 PM") {
        self.id = id
        self.userId = userId
        self.providerUserId = providerUserId
        self.serviceId = serviceId
        self.serviceName = serviceName
        self.providerName = providerName
        self.serviceImageUrl = serviceImageUrl
        self.date = date
        self.status = status
        self.price = price
        self.location = location
        self.rating = rating
        self.notes = notes
        self.addressId = addressId
        self.addressDetails = addressDetails
        self.timeSlot = timeSlot // Added this line to set the timeSlot property
    }
    
    // Helper method to get the formatted address
    func getFormattedAddress() -> String? {
        guard let details = addressDetails else { return nil }
        
        if let address = details["address"],
           let city = details["city"],
           let state = details["state"],
           let zipCode = details["zipCode"] {
            return "\(address), \(city), \(state) \(zipCode)"
        }
        return nil
    }
}

// MARK: - ViewModel
// MARK: - ViewModel
class BookingsViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var isLoading = false
    @Published var filters: [String: Any] = [:]
    @Published var showPendingOnly: Bool = false // New filter toggle for pending
    
    // Additional properties for user data
    var currentUserName: String = ""
    var userDataCache: [String: [String: String]] = [:]
    
    private let db = Firestore.firestore()
    
    
    
    func fetchBookings() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        // First fetch the current user's data to get their full name
        let userRef = db.collection("userData").document(userId)
        
        userRef.getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            var userName = userId // Default to userId if we can't get the name
            
            if let document = document, document.exists {
                let userData = document.data()
                userName = userData?["fullName"] as? String ?? userId
            }
            
            // Now proceed with fetching bookings using the user's name
            var query: Query = self.db.collection("bookings").whereField("userId", isEqualTo: userId)
            
            // Apply filters
            if let serviceType = self.filters["serviceType"] as? String {
                query = query.whereField("serviceType", isEqualTo: serviceType)
            }
            
            if let dateFrom = self.filters["dateFrom"] as? Date {
                query = query.whereField("date", isGreaterThanOrEqualTo: Timestamp(date: dateFrom))
            }
            
            if let sortBy = self.filters["sortBy"] as? String {
                let sortDesc = (self.filters["sortOrder"] as? String) == "desc"
                query = query.order(by: sortBy, descending: sortDesc)
            } else {
                // Default sort by date (newest first)
                query = query.order(by: "date", descending: true)
            }
            
            query.getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching bookings: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }
                
                let fetchedBookings = snapshot?.documents.compactMap { Booking(document: $0) } ?? []
                
                // For completed bookings, fetch provider user data
                let group = DispatchGroup()
                
                for booking in fetchedBookings where booking.status == .completed {
                    // For completed bookings, fetch the provider's user data
                    if let providerUserId = booking.providerName {
                        group.enter()
                        
                        let providerRef = self.db.collection("userData").document(providerUserId)
                        providerRef.getDocument { document, error in
                            defer { group.leave() }
                            
                            if let document = document, document.exists,
                               let providerData = document.data() {
                                if let fullName = providerData["fullName"] as? String {
                                    self.userDataCache[providerUserId] = [
                                        "fullName": fullName,
                                        "email": providerData["email"] as? String ?? "",
                                        "contact": providerData["phoneNumber"] as? String ?? ""
                                    ]
                                }
                            }
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self.bookings = fetchedBookings
                    self.currentUserName = userName
                    self.isLoading = false
                }
            }
        }
    }
    
    // Helper method to get user information
    func getUserInfo(for userId: String, infoType: String) -> String {
        return userDataCache[userId]?[infoType] ?? ""
    }
    
    // Modified function to filter bookings by tab and pending status
    func bookingsForTab(_ tab: BookingTab) -> [Booking] {
        switch tab {
        case .upcoming:
            if showPendingOnly {
                return bookings.filter { $0.status == .pending }
            } else {
                return bookings.filter { $0.status == .pending || $0.status == .confirmed || $0.status == .inProgress }
            }
        case .completed:
            return bookings.filter { $0.status == .completed }
        case .cancelled:
            return bookings.filter { $0.status == .cancelled }
        }
    }
    
    func cancelBooking(_ booking: Booking) {
        guard let userId = Auth.auth().currentUser?.uid else {
            // For testing with mock data
            if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
                // Create a new cancelled booking based on the original
                let cancelledBooking = Booking(
                    id: booking.id,
                    userId: booking.userId, providerUserId: "",
                    serviceId: booking.serviceId,
                    serviceName: booking.serviceName,
                    providerName: booking.providerName,
                    serviceImageUrl: booking.serviceImageUrl,
                    date: booking.date,
                    status: .cancelled,
                    price: booking.price,
                    location: booking.location,
                    rating: booking.rating,
                    notes: booking.notes
                )
                
                // Replace the booking
                bookings[index] = cancelledBooking
            }
            return
        }
        
        let bookingRef = db.collection("bookings").document(booking.id)
        
        bookingRef.updateData([
            "status": BookingStatus.cancelled.rawValue,
            "cancelledAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error cancelling booking: \(error.localizedDescription)")
            } else {
                self.fetchBookings()
            }
        }
    }
    
    func rebookService(_ booking: Booking) {
        guard let userId = Auth.auth().currentUser?.uid else {
            // For testing with mock data
            if let originalIndex = bookings.firstIndex(where: { $0.id == booking.id }) {
                // Create a new pending booking based on the original, with a future date
                let now = Date()
                let calendar = Calendar.current
                let futureDate = calendar.date(byAdding: .day, value: 7, to: now) ?? now
                
                let newBooking = Booking(
                    id: "rebooked\(booking.id)",
                    userId: booking.userId, providerUserId: "",
                    serviceId: booking.serviceId,
                    serviceName: booking.serviceName,
                    providerName: booking.providerName,
                    serviceImageUrl: booking.serviceImageUrl,
                    date: futureDate,
                    status: .pending,
                    price: booking.price,
                    location: booking.location,
                    rating: 0,
                    notes: "Rebooked from \(booking.id)"
                )
                
                // Add the new booking
                bookings.append(newBooking)
            }
            return
        }
        
        // Example: Add to cart collection
        let cartRef = db.collection("users").document(userId).collection("cart").document()
        
        cartRef.setData([
            "serviceId": booking.serviceId,
            "serviceName": booking.serviceName,
            "price": booking.price ?? "",
            "addedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error adding service to cart: \(error.localizedDescription)")
            }
        }
    }
    
    func rateBooking(_ booking: Booking, rating: Int) {
        guard let userId = Auth.auth().currentUser?.uid else {
            // For testing with mock data
            if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
                // Create a new rated booking based on the original
                let ratedBooking = Booking(
                    id: booking.id,
                    userId: booking.userId, providerUserId: "",
                    serviceId: booking.serviceId,
                    serviceName: booking.serviceName,
                    providerName: booking.providerName,
                    serviceImageUrl: booking.serviceImageUrl,
                    date: booking.date,
                    status: booking.status,
                    price: booking.price,
                    location: booking.location,
                    rating: rating,
                    notes: booking.notes
                )
                
                // Replace the booking
                bookings[index] = ratedBooking
            }
            return
        }
        
        let bookingRef = db.collection("bookings").document(booking.id)
        
        bookingRef.updateData([
            "rating": rating,
            "ratedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error rating booking: \(error.localizedDescription)")
            } else {
                self.fetchBookings()
                
                // Also update service average rating
                self.updateServiceRating(serviceId: booking.serviceId, rating: rating)
            }
        }
    }
    
    private func updateServiceRating(serviceId: String, rating: Int) {
        let serviceRef = db.collection("services").document(serviceId)
        
        // Transaction to update service rating
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let serviceDocument: DocumentSnapshot
            do {
                try serviceDocument = transaction.getDocument(serviceRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = serviceDocument.data(),
                  let currentRating = data["rating"] as? Double,
                  let ratingCount = data["ratingCount"] as? Int else {
                // If no existing rating, set initial rating
                transaction.updateData([
                    "rating": Double(rating),
                    "ratingCount": 1
                ], forDocument: serviceRef)
                return nil
            }
            
            // Calculate new average rating
            let totalPoints = currentRating * Double(ratingCount)
            let newTotal = totalPoints + Double(rating)
            let newCount = ratingCount + 1
            let newAverage = newTotal / Double(newCount)
            
            transaction.updateData([
                "rating": newAverage,
                "ratingCount": newCount
            ], forDocument: serviceRef)
            
            return nil
        }) { (_, error) in
            if let error = error {
                print("Error updating service rating: \(error.localizedDescription)")
            }
        }
    }
}
