import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [Service] = []
    @Published var isSearching: Bool = false
    @Published var recentSearches: [String] = []
    @Published var hasSearched: Bool = false  // New flag to track if search has been performed
    
    let popularSearches = ["Haircut", "Massage", "Home Cleaning", "Car Wash", "Plumbing"]
    
    private var db = Firestore.firestore()
    
    init(initialSearchText: String = "") {
        self.searchText = initialSearchText
        loadRecentSearches()
        
        // Automatically perform search if initialSearchText is provided
        if !initialSearchText.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.search()
            }
        }
    }
    
    func search() {
        self.hasSearched = true  // Mark that search has been attempted
        
        guard !searchText.isEmpty else {
            // Clear results if search is empty
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        print("Searching for: \(searchText)")  // Debug log
        
        // Add to recent searches
        if !searchText.isEmpty && !recentSearches.contains(searchText) {
            recentSearches.insert(searchText, at: 0)
            if recentSearches.count > 5 {
                recentSearches = Array(recentSearches.prefix(5))
            }
            saveRecentSearches()
        }
        
        // Prepare search terms
        let searchTerms = searchText.lowercased().split(separator: " ").map { String($0) }
        
        // Query Firestore
        db.collection("services")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isSearching = false
                    
                    if let error = error {
                        print("Error searching: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let snapshot = snapshot else {
                        self.searchResults = []
                        return
                    }
                    
                    print("Got \(snapshot.documents.count) documents from Firestore")  // Debug log
                    
                    // Get all services
                    let allServices = snapshot.documents.compactMap { Service(document: $0) }
                    print("Parsed \(allServices.count) services")  // Debug log
                    
                    // Filter based on search terms
                    self.searchResults = allServices.filter { service in
                        let name = service.name.lowercased()
                        let description = service.description?.lowercased() ?? ""
                        
                        // Check if any search term is in name or description
                        return searchTerms.contains { term in
                            name.contains(term) || description.contains(term)
                        }
                    }
                    
                    print("Filtered to \(self.searchResults.count) matching results")  // Debug log
                    
                    // Sort by relevance (exact matches first, then partial)
                    self.searchResults.sort { service1, service2 in
                        let name1 = service1.name.lowercased()
                        let name2 = service2.name.lowercased()
                        
                        // Check for exact match in the name
                        let exactMatch1 = name1 == self.searchText.lowercased()
                        let exactMatch2 = name2 == self.searchText.lowercased()
                        
                        if exactMatch1 && !exactMatch2 {
                            return true
                        } else if !exactMatch1 && exactMatch2 {
                            return false
                        }
                        
                        // Check if name starts with search text
                        let nameStarts1 = name1.starts(with: self.searchText.lowercased())
                        let nameStarts2 = name2.starts(with: self.searchText.lowercased())
                        
                        if nameStarts1 && !nameStarts2 {
                            return true
                        } else if !nameStarts1 && nameStarts2 {
                            return false
                        }
                        
                        // Sort by rating as a fallback
                        return service1.rating > service2.rating
                    }
                }
            }
    }
    
    // Mock search for testing
    func mockSearch() {
        self.hasSearched = true
        isSearching = true
        
        // Add to recent searches
        if !searchText.isEmpty && !recentSearches.contains(searchText) {
            recentSearches.insert(searchText, at: 0)
            if recentSearches.count > 5 {
                recentSearches = Array(recentSearches.prefix(5))
            }
            saveRecentSearches()
        }
        
    }
    
    // Save recent searches to UserDefaults
    private func saveRecentSearches() {
        if let userId = Auth.auth().currentUser?.uid {
            UserDefaults.standard.set(recentSearches, forKey: "recentSearches_\(userId)")
        }
    }
    
    // Load recent searches from UserDefaults
    private func loadRecentSearches() {
        if let userId = Auth.auth().currentUser?.uid,
           let searches = UserDefaults.standard.stringArray(forKey: "recentSearches_\(userId)") {
            recentSearches = searches
        }
    }
    
    // Clear all recent searches
    func clearRecentSearches() {
        recentSearches = []
        if let userId = Auth.auth().currentUser?.uid {
            UserDefaults.standard.removeObject(forKey: "recentSearches_\(userId)")
        }
    }
}
