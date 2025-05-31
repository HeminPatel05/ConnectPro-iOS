import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct HomeView: View {
    // Firebase State
    @StateObject private var viewModel = HomeViewModel()
    @State private var searchText = ""
    @State private var currentBannerIndex = 0
    @State private var selectedCategory: String?
    @State private var showSignInView = false
    @State private var showSearchResults = false
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    // Demo Data - Will be replaced with Firebase data
    private let recommendedSearches = ["Haircut", "Gym Trainer", "Yoga", "Car Wash", "Plumber"]
    private let banners = ["promo1", "promo2", "promo3"]
    
    var body: some View {
        Group {
            if viewModel.isSignedIn {
                mainHomeView
            } else {
                // Show sign-in prompt
                VStack {
                    Text("Please sign in to continue")
                        .font(.headline)
                    
                    Button("Sign In") {
                        showSignInView = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .fullScreenCover(isPresented: $showSignInView) {
                    // This would be your sign-in view
                    // After successful sign-in, set viewModel.isSignedIn = true
                    Text("Sign In View")
                }
            }
        }
        .onAppear {
            // Check authentication state when view appears
            viewModel.checkAuthState()
            // Load data from Firebase
            viewModel.fetchCategories()
            viewModel.fetchPopularServices()
            viewModel.fetchUserHistory()
        }
    }
    
    private var mainHomeView: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Search Section
                        searchSection
                        
                        // Categories
                        categoriesSection
                        
                        // Popular Services - Only show if there are active services
                        if !viewModel.activePopularServices.isEmpty {
                            popularServicesSection
                        }
                        
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.bottom, 16)
                }
                
                // Navigation links for search
                NavigationLink(
                    destination: SearchHistoryView(viewModel: SearchViewModel()),
                    isActive: $showSearchResults,
                    label: { EmptyView() }
                )
            }
            .onAppear {
                // This will refresh the history every time you return to this view
                print("🔄 Main home view appeared - refreshing history")
                viewModel.fetchUserHistory()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Spacer()
                        // Logo centered
                        Text("Connect Pro")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 12) {
            // Search Bar (now triggering navigation)
            NavigationLink(destination: SearchResultsView(viewModel: SearchViewModel(initialSearchText: searchText))) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    Text(searchText.isEmpty ? "Search for a service" : searchText)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: "mic.fill")
                        .foregroundColor(.gray)
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Recommended Searches
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recommendedSearches, id: \.self) { search in
                        NavigationLink(destination: SearchResultsView(viewModel: SearchViewModel(initialSearchText: search))) {
                            HStack {
                                Image(systemName: serviceSFSymbol(for: search))
                                Text(search)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Categories Section
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading) {
            Text("Categories")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.isLoadingCategories {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else if viewModel.categories.isEmpty {
                Text("No categories available")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(viewModel.categories) { category in
                        NavigationLink(destination: CategoryDetailView(category: category)) {
                            VStack {
                                Image(systemName: category.iconName!)
                                    .font(.system(size: 25))
                                    .foregroundColor(.blue)
                                    .frame(width: 60, height: 60)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                                
                                Text(category.name)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onTapGesture {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            viewModel.selectCategory(category)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Popular Services Section
    private var popularServicesSection: some View {
        VStack(alignment: .leading) {
            Text("Popular Services")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.isLoadingServices {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else if viewModel.activePopularServices.isEmpty {
                Text("No services available")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(viewModel.activePopularServices) { service in
                            serviceCard(service: service)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    // MARK: - Service Card with Navigation
    private func serviceCard(service: Service) -> some View {
        let bookingViewModel = BookingViewModel(service: service)
        return NavigationLink(destination: ServiceDetailView(service: service)) {
            VStack(alignment: .leading) {
                // Image - Using service.imageUrl if available
                if let imageUrl = service.imageUrl, !imageUrl.isEmpty {
                    // AsyncImage would load from Firebase Storage
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 200, height: 120) // Increased from 160x100
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 200, height: 120) // Increased from 160x100
                                .cornerRadius(10)
                        case .failure:
                            // Fallback to placeholder with icon
                            Rectangle()
                                .fill(serviceColor(for: service.id))
                                .frame(width: 200, height: 120) // Increased from 160x100
                                .cornerRadius(10)
                                .overlay(
                                    Image(systemName: serviceSFSymbol(for: service.name))
                                        .font(.system(size: 35)) // Slightly increased from 30
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(serviceColor(for: service.id))
                                .frame(width: 200, height: 120) // Increased from 160x100
                                .cornerRadius(10)
                        }
                    }
                } else {
                    // Fallback for no image URL
                    Rectangle()
                        .fill(serviceColor(for: service.id))
                        .frame(width: 200, height: 120) // Increased from 160x100
                        .cornerRadius(10)
                        .overlay(
                            Image(systemName: serviceSFSymbol(for: service.name))
                                .font(.system(size: 35)) // Slightly increased from 30
                                .foregroundColor(.white)
                        )
                }
                
                // Details
                VStack(alignment: .leading, spacing: 6) { // Increased spacing from 4
                    Text(service.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(service.price)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    // Modal presentation button for BookingTimeSelectionView
                    ModalButton(
                        label: Text("Book Now")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14) // Increased from 12
                            .background(Color.blue)
                            .cornerRadius(15),
                        destination: BookingTimeSelectionView(viewModel: bookingViewModel)
                    )
                    .padding(.top, 6) // Increased from 5
                }
                .padding(10) // Increased from 8
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .frame(width: 200, height: 260) // Increased from 160x220
        }
        .buttonStyle(PlainButtonStyle()) // This keeps the original appearance
        .onTapGesture {
            viewModel.viewServiceDetail(service: service)
        }
    }
    
    // Helper struct for modal presentation
        struct ModalButton<Label: View, Destination: View>: View {
            @State private var isPresented = false
            let label: Label
            let destination: Destination
            
            var body: some View {
                Button(action: {
                    isPresented = true
                }) {
                    label
                }
                .sheet(isPresented: $isPresented) {
                    destination
                }
            }
        }
    
    // MARK: - Continue Where You Left Off Section
    private var continueWhereYouLeftOffSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Continue Where You Left Off")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.isLoadingHistory {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .padding()
            } else if viewModel.recentlyViewedServices.isEmpty {
                EmptyHistoryView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(viewModel.recentlyViewedServices) { service in
                            recentServiceCard(service: service)
                                .onAppear {
                                    print("📱 Displaying recent service card: \(service.name)")
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // Empty history view with helpful message
    private struct EmptyHistoryView: View {
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
                
                Text("No recent activity")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                
                Text("Services you view will appear here")
                    .foregroundColor(.gray.opacity(0.7))
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(Color.white.opacity(0.5))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }

    // MARK: - Enhanced Recent Service Card
    private func recentServiceCard(service: RecentService) -> some View {
        RecentServiceCardWrapper(recentService: service, viewModel: viewModel)
            .transition(.opacity)
            .id(service.id) // Force a redraw if the service changes
    }

    // MARK: - RecentServiceCardWrapper (Enhanced version)
    struct RecentServiceCardWrapper: View {
        let recentService: RecentService
        @ObservedObject var viewModel: HomeViewModel
        @State private var service: Service?
        @State private var isLoading = true
        @State private var showBookingSheet = false
        
        var body: some View {
            Group {
                if isLoading {
                    loadingPlaceholder
                } else if let service = service {
                    recentServiceCardWithNavigation(service: service)
                } else {
                    recentServiceCardContent
                        .onTapGesture {
                            viewModel.selectRecentService(recentService)
                        }
                }
            }
            .onAppear {
                fetchServiceDetails()
            }
            
        }
        
        // Loading placeholder
        private var loadingPlaceholder: some View {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                        .frame(width: 120)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 10)
                        .frame(width: 80)
                }
                .frame(width: 150, alignment: .leading)
                
                Spacer()
            }
            .padding(10)
            .frame(width: 250)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .redacted(reason: .placeholder)
        }
        
        // Service card with navigation
        private func recentServiceCardWithNavigation(service: Service) -> some View {
            NavigationLink(destination: ServiceDetailView(service: service)) {
                ZStack {
                    recentServiceCardContent
                    
                    HStack {
                        Spacer()
                        
                        VStack {
                            Spacer()
                            
                            Button(action: {
                                self.showBookingSheet = true
                            }) {
                                Text("Book")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(Color.blue)
                                    .cornerRadius(15)
                            }
                            .padding(10)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showBookingSheet) {
                BookingTimeSelectionView(viewModel: BookingViewModel(service: service))
            }
        }
        
        // Basic card content
        private var recentServiceCardContent: some View {
            HStack(spacing: 12) {
                // Service icon or image
                ZStack {
                    Rectangle()
                        .fill(serviceColor(for: recentService.id))
                        .frame(width: 60, height: 60)
                        .cornerRadius(10)
                    
                    if let service = service, let imageUrl = service.imageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(10)
                            default:
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recentService.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        Text(recentService.lastViewedFormatted)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    if let service = service {
                        Text(service.price)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
            .padding(10)
            .frame(width: 250)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        
        private func fetchServiceDetails() {
            isLoading = true
            
            // Try to fetch the service from Firestore
            let db = Firestore.firestore()
            db.collection("services").document(recentService.serviceId).getDocument { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        print("Error fetching service: \(error.localizedDescription)")
                        return
                    }
                    
                    if let document = snapshot,
                       document.exists,
                       let documentSnapshot = document as? QueryDocumentSnapshot {
                        self.service = Service(document: documentSnapshot)
                    }
                }
            }
        }
        
        // Helper function to maintain consistent coloring
        private func serviceColor(for id: Int) -> Color {
            let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink]
            return colors[abs(id) % colors.count]
        }
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
    
    private func categorySFSymbol(for category: String) -> String {
        switch category.lowercased() {
        case "salon":
            return "scissors"
        case "home cleaning":
            return "house.fill"
        case "repairs":
            return "wrench.and.screwdriver.fill"
        case "wellness":
            return "heart.fill"
        case "fitness":
            return "figure.walk"
        case "pet care":
            return "pawprint.fill"
        default:
            return "star.fill"
        }
    }
    
    func serviceColor(for serviceId: String) -> Color {
        // Convert the string to a consistent integer value for color selection
        let hash = serviceId.hash
        
        // Use the hash value modulo some number to select a color
        let colorIndex = abs(hash % 6) // Assuming you have 6 colors to choose from
        
        // Return color based on the index
        switch colorIndex {
        case 0:
            return .blue
        case 1:
            return .green
        case 2:
            return .orange
        case 3:
            return .purple
        case 4:
            return .red
        case 5:
            return .pink
        default:
            return .gray
        }
    }
}

extension HomeViewModel {
    // Computed property that returns only active popular services
    var activePopularServices: [Service] {
        return popularServices.filter { service in
            // Check if the service has an isActive property and if it's true
            return (service.isActive == true)
        }
    }
}
