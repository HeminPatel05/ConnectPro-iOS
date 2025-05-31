import SwiftUI
import Firebase
import FirebaseFirestore

struct SearchResultsView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var searchTriggered = false
    
    var body: some View {
        VStack {
            // Search header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for a service", text: $viewModel.searchText)
                        .onSubmit {
                            // This ensures search happens when submit button is pressed
                            viewModel.search()
                        }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                            viewModel.search()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    } else {
                        Button(action: {
                            // Voice search action
                        }) {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 5)
            
            // Main content
            if viewModel.isSearching {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.hasSearched {
                // Initial state - show suggestions
                initialSearchSuggestions
            } else if viewModel.searchResults.isEmpty {
                // No results state
                noResultsView
            } else {
                // Results state
                searchResultsList
            }
        }
        .navigationBarHidden(true)
        .background(Color(.systemGray6).ignoresSafeArea())
        .onAppear {
            // Trigger search automatically on appear if text exists
            if !viewModel.searchText.isEmpty && !searchTriggered {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.search()
                    searchTriggered = true
                }
            }
        }
    }
    
    // Initial search state with suggestions
    private var initialSearchSuggestions: some View {
        VStack(spacing: 20) {
            Text("What are you looking for?")
                .font(.headline)
                .padding(.top, 40)
            
            // Popular searches
            VStack(alignment: .leading, spacing: 15) {
                Text("Popular Searches")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                ForEach(viewModel.popularSearches, id: \.self) { search in
                    Button(action: {
                        viewModel.searchText = search
                        viewModel.search()
                    }) {
                        HStack {
                            Image(systemName: serviceSFSymbol(for: search))
                                .foregroundColor(.blue)
                            Text(search)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 15)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // No results state
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.7))
            
            Text("No results found")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Try a different search term or browse categories")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Popular searches suggestion
            VStack(alignment: .leading, spacing: 10) {
                Text("Popular searches")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                ForEach(viewModel.popularSearches, id: \.self) { search in
                    Button(action: {
                        viewModel.searchText = search
                        viewModel.search()
                    }) {
                        HStack {
                            Image(systemName: serviceSFSymbol(for: search))
                                .foregroundColor(.blue)
                            Text(search)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(15)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }
    
    // Search results list
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                // Results count
                HStack {
                    Text("\(viewModel.searchResults.count) result\(viewModel.searchResults.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 5)
                
                // Results
                ForEach(viewModel.searchResults) { service in
                    NavigationLink(destination: ServiceDetailView(service: service)) {
                        SearchResultRow(service: service)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    // Helper for service icons
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
        case _ where service.lowercased().contains("massage"):
            return "hand.wave.fill"
        default:
            return "star.fill"
        }
    }
}

// Search result row component
struct SearchResultRow: View {
    let service: Service
    
    var body: some View {
        HStack(spacing: 15) {
            // Service image
            if let imageUrl = service.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        serviceImagePlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(10)
                    case .failure:
                        serviceImagePlaceholder
                    @unknown default:
                        serviceImagePlaceholder
                    }
                }
            } else {
                serviceImagePlaceholder
            }
            
            // Service details
            VStack(alignment: .leading, spacing: 5) {
                Text(service.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let description = service.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                HStack {

                    // Price
                    Text(service.price)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var serviceImagePlaceholder: some View {
        Rectangle()
            .fill(serviceColor(for: service.id))
            .frame(width: 80, height: 80)
            .cornerRadius(10)
            .overlay(
                Image(systemName: serviceSFSymbol(for: service.name))
                    .font(.system(size: 25))
                    .foregroundColor(.white)
            )
    }
    
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
