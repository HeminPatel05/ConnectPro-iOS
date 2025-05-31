import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct ServiceDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: ServiceDetailViewModel
    
    init(service: Service) {
        _viewModel = StateObject(wrappedValue: ServiceDetailViewModel(service: service))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                headerSection
                
                // Service Info
                serviceInfoSection
                
                // Description
                descriptionSection
                
                // Service Provider
                providerSection
                
                
                // Book Button
                bookButtonSection
            }
            .padding(.bottom, 100)
        }
        .background(Color(.systemGray6))
        .edgesIgnoringSafeArea(.top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
            }
            
        }
        .onAppear {
            // Record this view in user history for "Continue Where You Left Off"
            viewModel.recordServiceView()
            
            // Fetch other details
            viewModel.fetchServiceDetails()
            viewModel.fetchReviews()
        }
        .sheet(isPresented: $viewModel.showingBookingTimeSelection) {
            BookingTimeSelectionView(viewModel: BookingViewModel(service: viewModel.service))
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageUrl = viewModel.service.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(height: 250)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: serviceSFSymbol(for: viewModel.service.name))
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(height: 250)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 250)
                    .overlay(
                        Image(systemName: serviceSFSymbol(for: viewModel.service.name))
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    )
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.serviceCategory)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(15)
                }
                .padding(.bottom, 16)
                .padding(.leading, 16)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Service Info Section
    private var serviceInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Left side content
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.service.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    
                    Text(viewModel.service.price)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right side - add button
                VStack(alignment: .trailing, spacing: 10) {
                    Button(action: {
                        viewModel.showingBookingTimeSelection = true
                    }) {
                        HStack {
                            Text("Book")
                        }
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .background(Color.white)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .offset(y: -20)
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)
            
            if viewModel.showFullDescription {
                Text(viewModel.fullDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    viewModel.toggleShowFullDescription()
                }) {
                    Text("Show Less")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            } else {
                Text(viewModel.shortDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                Button(action: {
                    viewModel.toggleShowFullDescription()
                }) {
                    Text("Read More")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Provider Section
    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Service Provider")
                .font(.headline)
            
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(viewModel.providerName.prefix(1)))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.providerName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
            
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.contactProvider()
                }) {
                    Text("Contact")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
   
    
    // MARK: - Similar Services Section
    private var similarServicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You May Also Like")
                .font(.headline)
            
            if viewModel.isLoadingSimilarServices {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else if viewModel.similarServices.isEmpty {
                Text("No similar services found")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(viewModel.similarServices) { service in
                            similarServiceCard(service: service)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func similarServiceCard(service: Service) -> some View {
        VStack(alignment: .leading) {
            if let imageUrl = service.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 140, height: 100)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 100)
                            .cornerRadius(10)
                    case .failure:
                        Rectangle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 140, height: 100)
                            .cornerRadius(10)
                            .overlay(
                                Image(systemName: serviceSFSymbol(for: service.name))
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 140, height: 100)
                            .cornerRadius(10)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 140, height: 100)
                    .cornerRadius(10)
                    .overlay(
                        Image(systemName: serviceSFSymbol(for: service.name))
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    )
            }
            
            Text(service.name)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(1)
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption2)
                
                Text(String(format: "%.1f", service.rating))
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            
            Text(service.price)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .frame(width: 140)
        .padding(8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .onTapGesture {
            viewModel.navigateToService(service: service)
        }
    }
    
    // MARK: - Book Button Section
    private var bookButtonSection: some View {
        VStack {
            Button(action: {
                viewModel.bookService()
            }) {
                Text("Book Now")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    private func serviceSFSymbol(for service: String) -> String {
        switch service.lowercased() {
        case _ where service.lowercased().contains("haircut"):
            return "scissors"
        case _ where service.lowercased().contains("gym"):
            return "dumbbell.fill"
        case _ where service.lowercased().contains("yoga"):
            return "figure.yoga"
        case _ where service.lowercased().contains("car"):
            return "car.fill"
        case _ where service.lowercased().contains("plumber"):
            return "wrench.fill"
        case _ where service.lowercased().contains("clean"):
            return "house.fill"
        case _ where service.lowercased().contains("repair"):
            return "wrench.and.screwdriver.fill"
        case _ where service.lowercased().contains("spa"):
            return "sparkles"
        default:
            return "star.fill"
        }
    }
}

// MARK: - Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - View Models
class ServiceDetailViewModel: ObservableObject {
    @Published var service: Service
    @Published var similarServices: [Service] = []
    @Published var showFullDescription: Bool = false
    @Published var reviewCount: Int = 0
    @Published var serviceCategory: String = ""
    @Published var showingBookingTimeSelection: Bool = false
    @Published var providerEmail: String = ""
    
    @Published var isLoadingReviews: Bool = false
    @Published var isLoadingSimilarServices: Bool = false
    
    // Provider info
    @Published var providerName: String = "Professional Provider"
    @Published var providerRating: Double = 4.8
    @Published var providerServiceCount: Int = 150
    
    // Description
    @Published var shortDescription: String = "Description loading..."
    @Published var fullDescription: String = "Full description loading..."
    
    private var db = Firestore.firestore()
    
    init(service: Service) {
        self.service = service
        
        // Set default descriptions based on available data
        if let description = service.description, !description.isEmpty {
            self.shortDescription = description
            self.fullDescription = description
        } else {
            self.shortDescription = "Professional \(service.name) service with high-quality tools and experienced staff."
            self.fullDescription = "Professional \(service.name) service with high-quality tools and experienced staff. Our team ensures customer satisfaction with every booking. We use premium products and follow industry best practices to provide you with an exceptional experience."
        }
    }
    
    // Add to ServiceDetailViewModel class
    func recordServiceView() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ recordServiceView: No user ID found!")
            return
        }
        
        print("📝 Recording service view in history: \(service.name) (ID: \(service.id))")
        
        // Reference to history document
        let historyRef = db.collection("userData").document(userId).collection("history").document("\(service.id)")
        
        // Convert service ID to numeric value if it's not already
        let numericId: Int
        if let id = Int(service.id) {
            numericId = id
        } else {
            // Create a hash from the ID string
            numericId = abs(service.id.hashValue) % 10000
        }
        
        // Create consistent history data with numeric ID
        let historyData: [String: Any] = [
            "id": numericId,
            "name": service.name,
            "serviceId": service.id,
            "lastViewed": FieldValue.serverTimestamp()
        ]
        
        print("💾 Saving history data: \(historyData)")
        
        // Save to Firestore
        historyRef.setData(historyData, merge: true) { error in
            if let error = error {
                print("❌ Error saving to history: \(error.localizedDescription)")
            } else {
                print("✅ Successfully recorded service view in history")
                
                // Note: We don't need to refresh here since the HomeViewModel will
                // fetch history when the user returns to the home screen
            }
        }
    }
    
    func fetchServiceDetails() {
        // Fetch category
        if !service.categoryId.isEmpty {
            db.collection("categories").document(service.categoryId).getDocument { [weak self] document, error in
                if let document = document, document.exists, let data = document.data(), let categoryName = data["name"] as? String {
                    DispatchQueue.main.async {
                        self?.serviceCategory = categoryName
                    }
                }
            }
        }
        
        // Fetch provider info using providerUserId
        if let providerUserId = service.providerUserId, !providerUserId.isEmpty {
            db.collection("userData").document(providerUserId).getDocument { [weak self] document, error in
                if let document = document, document.exists, let data = document.data() {
                    DispatchQueue.main.async {
                        if let name = data["fullName"] as? String {
                            self?.providerName = name
                        }
                        else {
                            // Fallback if name fields aren't found
                            self?.providerName = "Service Provider"
                        }
                        
                        if let email = data["email"] as? String {
                            self?.providerEmail = email
                        }
                        
                        // If there's provider rating in the user document
                        if let rating = data["rating"] as? Double {
                            self?.providerRating = rating
                        }
                        
                        // If there's completed service count in the user document
                        if let completedServices = data["completedServices"] as? Int {
                            self?.providerServiceCount = completedServices
                        }
                    }
                } else {
                    // Fallback if provider document can't be fetched
                    DispatchQueue.main.async {
                        self?.providerName = "Service Provider"
                    }
                }
            }
        } else {
            // Fallback if providerUserId is nil or empty
            DispatchQueue.main.async {
                self.providerName = "Service Provider"
            }
        }
    }
    
    func fetchReviews() {
        isLoadingReviews = true
        
        // In a real app, this would fetch from Firebase
        // For demo purposes, we'll create dummy reviews
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            
            self.reviewCount = Int.random(in: 10...50)
            self.isLoadingReviews = false
        }
    }
    
    func toggleShowFullDescription() {
        showFullDescription.toggle()
    }
    
    func addToCart() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let cartRef = db.collection("userData").document(userId).collection("cart").document("\(service.id)")
        
        cartRef.setData([
            "id": service.id,
            "name": service.name,
            "price": service.price,
            "addedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
    
    func bookService() {
        // Show booking selection sheet
        showingBookingTimeSelection = true
    }
    
    func contactProvider() {
        // Check if we have a valid email address
        if !providerEmail.isEmpty, let url = URL(string: "mailto:\(providerEmail)") {
            // Open email client
            UIApplication.shared.open(url)
        } else {
            // Handle the case where no email is available
            print("No email available for provider: \(providerName)")
            // You could show an alert here to inform the user
        }
    }
    
    func navigateToService(service: Service) {
        print("Navigate to service: \(service.name)")
        // In a real app, this would navigate to the selected service detail
        
        // Record this new service view in history as well
        self.service = service
        recordServiceView()
    }
}
