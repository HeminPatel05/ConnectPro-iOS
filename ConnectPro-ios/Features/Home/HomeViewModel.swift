import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

class HomeViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var categories: [Category] = []
    @Published var popularServices: [Service] = []
    @Published var recentlyViewedServices: [RecentService] = []
    @Published var userLocation = "Fetching location..."
    @Published var cartItemCount = 0
    @Published var showCartView = false
    @Published var showLocationSelector = false
    @Published var isLocationServicesEnabled = true
    
    @Published var isLoadingCategories = false
    @Published var isLoadingServices = false
    @Published var isLoadingHistory = false
    @Published var isLoadingLocation = false
    
    private var db = Firestore.firestore()
    private var authStateDidChangeListener: AuthStateDidChangeListenerHandle?
    private let locationManager = CLLocationManager()
    private var locationFetcher: LocationFetcher?
    
    init() {
        checkAuthState()
        setupLocationFetcher()
    }
    
    private func setupLocationFetcher() {
        locationFetcher = LocationFetcher()
        locationFetcher?.onLocationUpdate = { [weak self] location in
            self?.handleLocationUpdate(location)
        }
        locationFetcher?.onLocationError = { [weak self] error in
            self?.handleLocationError(error)
        }
    }
    
    func checkAuthState() {
        authStateDidChangeListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            DispatchQueue.main.async {
                self?.isSignedIn = user != nil
                
                if user != nil {
                    // User is signed in, load their data
                    self?.fetchUserData()
                }
            }
        }
    }
    
    func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Fetch user profile data including location
        db.collection("userData").document(userId).getDocument { [weak self] document, error in
            if let document = document, document.exists, let data = document.data() {
                DispatchQueue.main.async {
                    if let location = data["location"] as? String {
                        self?.userLocation = location
                    } else {
                        // If no location is saved, fetch the current location
                        self?.fetchCurrentLocation()
                    }
                }
            } else {
                // If user document doesn't exist or has no location, fetch the current location
                self?.fetchCurrentLocation()
            }
        }
        
        // Fetch cart count
        db.collection("userData").document(userId).collection("cart").getDocuments { [weak self] snapshot, error in
            if let snapshot = snapshot {
                DispatchQueue.main.async {
                    self?.cartItemCount = snapshot.documents.count
                }
            }
        }
    }
    
    func fetchCurrentLocation() {
        isLoadingLocation = true
        
        // Request location
        locationFetcher?.requestLocation()
    }
    
    private func handleLocationUpdate(_ locationInfo: (name: String, coordinate: CLLocationCoordinate2D)) {
        DispatchQueue.main.async {
            self.isLoadingLocation = false
            self.userLocation = locationInfo.name
            
            // If the user is signed in, save the location to Firebase
            if self.isSignedIn {
                self.updateLocation(to: locationInfo.name)
            }
        }
    }
    
    private func handleLocationError(_ error: Error) {
        DispatchQueue.main.async {
            self.isLoadingLocation = false
            
            // Use a fallback location when there's an error
            if self.userLocation == "Fetching location..." {
                self.userLocation = "Location unavailable"
            }
            
            self.isLocationServicesEnabled = false
            print("Location error: \(error.localizedDescription)")
        }
    }
    
    func fetchCategories() {
        isLoadingCategories = true
        
        db.collection("categories").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoadingCategories = false
                
                if let error = error {
                    print("Error fetching categories: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else { return }
                
                self?.categories = snapshot.documents.compactMap { document in
                    return Category(document: document)
                }
            }
        }
    }
    
    func fetchPopularServices() {
        isLoadingServices = true
        
        db.collection("services")
            .whereField("isPopular", isEqualTo: true)
            .whereField("isActive", isEqualTo: true) // Only fetch active services
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoadingServices = false
                    
                    if let error = error {
                        print("Error fetching services: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let snapshot = snapshot else { return }
                    
                    self?.popularServices = snapshot.documents.compactMap { document in
                        return Service(document: document)
                    }
                }
            }
    }
    
    // Add this to fetchUserHistory() in HomeViewModel
    func fetchUserHistory() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ fetchUserHistory: No user ID found!")
            isLoadingHistory = false
            return
        }
        
        print("🔍 Fetching history for user: \(userId)")
        isLoadingHistory = true
        
        db.collection("userData").document(userId).collection("history")
            .order(by: "lastViewed", descending: true)
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoadingHistory = false
                    
                    if let error = error {
                        print("❌ Error fetching history: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        print("❌ No snapshot returned for history")
                        return
                    }
                    
                    print("📄 History documents count: \(snapshot.documents.count)")
                    
                    self?.recentlyViewedServices = snapshot.documents.compactMap { document in
                        let service = RecentService(document: document)
                        print("📋 Parsed history item: \(service?.name ?? "nil")")
                        return service
                    }
                    
                    print("✅ Updated recentlyViewedServices count: \(self?.recentlyViewedServices.count ?? 0)")
                }
            }
    }

    func viewServiceDetail(service: Service) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ viewServiceDetail: No user ID found!")
            return
        }
        
        print("📝 Adding service to history: \(service.name) (ID: \(service.id))")
        
        // Use a numeric ID for consistency
        let numericId = service.id
        
        // Add to user history - using the service ID as document ID
        let historyRef = db.collection("userData").document(userId).collection("history").document("\(service.id)")
        
        // Use consistent data format - always use numeric ID
        let historyData: [String: Any] = [
            "id": numericId,         // Numeric ID
            "name": service.name,
            "serviceId": "\(service.id)", // String version of ID
            "lastViewed": FieldValue.serverTimestamp()
        ]
        
        print("💾 Saving history data: \(historyData)")
        
        historyRef.setData(historyData, merge: true) { [weak self] error in
            if let error = error {
                print("❌ Error saving to history: \(error.localizedDescription)")
            } else {
                print("✅ Successfully added service to history")
                
                // Refresh the history to show the updated list
                DispatchQueue.main.async {
                    self?.fetchUserHistory()
                }
            }
        }
    }
    
    func selectCategory(_ category: Category) {
        // Navigate to category detail
        print("Selected category: \(category.name)")
    }
    
    
    func selectRecentService(_ service: RecentService) {
        // Fetch the full service details and then navigate
        db.collection("services").document(service.serviceId).getDocument { [weak self] document, error in
            if let document = document, document.exists,
               let serviceData = try? document.data() {
                // Navigation is handled by the view
                print("Selected recent service: \(service.name)")
            }
        }
    }
    
    func addToCart(service: Service) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let cartRef = db.collection("userData").document(userId).collection("cart").document("\(service.id)")
        
        // Add additional details to cart item
        cartRef.setData([
            "id": service.id,
            "name": service.name,
            "price": service.price,
            "imageUrl": service.imageUrl ?? "",
            "description": service.description ?? "",
            "categoryId": service.categoryId,
            "addedAt": FieldValue.serverTimestamp()
        ], merge: true) { [weak self] error in
            if let error = error {
                print("Error adding to cart: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self?.cartItemCount += 1
                    
                    // Show a toast or notification
                    self?.showAddToCartToast()
                }
            }
        }
    }
    
    private func showAddToCartToast() {
        // Show a toast notification for feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Additional UI feedback could be implemented here
    }
    
    func showLocationPicker() {
        // Show the location picker sheet/modal
        showLocationSelector = true
    }
    
    func updateLocation(to newLocation: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Update in view model
        userLocation = newLocation
        
        // Update in Firebase
        db.collection("userData").document(userId).updateData([
            "location": newLocation
        ]) { error in
            if let error = error {
                print("Error updating location: \(error.localizedDescription)")
            }
        }
        
        // Refresh services for the new location
        fetchPopularServices()
    }
    
    func showCart() {
        // Update to present the Cart View using sheet
        showCartView = true
    }
}

// Location fetcher to handle CoreLocation functionality
class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    var onLocationUpdate: ((name: String, coordinate: CLLocationCoordinate2D)) -> Void = { _ in }
    var onLocationError: (Error) -> Void = { _ in }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            onLocationError(NSError(domain: "LocationError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Location permissions denied"]))
        @unknown default:
            onLocationError(NSError(domain: "LocationError", code: 402, userInfo: [NSLocalizedDescriptionKey: "Unknown authorization status"]))
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            onLocationError(NSError(domain: "LocationError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Location permissions denied"]))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            // Reverse geocode to get the place name
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    self.onLocationError(error)
                    return
                }
                
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? "Unknown City"
                    let state = placemark.administrativeArea ?? ""
                    let country = placemark.country ?? ""
                    
                    let locationName = "\(city), \(state.isEmpty ? country : state)"
                    self.onLocationUpdate((name: locationName, coordinate: location.coordinate))
                } else {
                    // Fallback if geocoding doesn't return a placemark
                    self.onLocationError(NSError(domain: "LocationError", code: 403, userInfo: [NSLocalizedDescriptionKey: "No placemark found"]))
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onLocationError(error)
    }
}
