//
//  CategoryDetailView.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/26/25.
//


import SwiftUI
import Firebase
import FirebaseFirestore

struct CategoryDetailView: View {
    let category: Category
    @StateObject private var viewModel = CategoryViewModel()
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                    Text("Loading services...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            } else if viewModel.services.isEmpty {
                VStack {
                    Image(systemName: "tray")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No services available")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.services) { service in
                            ServiceCardView(service: service)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchServices(forCategory: category.id)
        }
    }
}

struct ServiceCardView: View {
    let service: Service
    @State private var showBookingSheet = false
    
    var body: some View {
        NavigationLink(destination: ServiceDetailView(service: service)) {
            VStack(alignment: .leading, spacing: 10) {
                // Service image
                if let imageUrl = service.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(12)
                        case .failure:
                            serviceColorPlaceholder(for: service.id)
                        @unknown default:
                            serviceColorPlaceholder(for: service.id)
                        }
                    }
                } else {
                    serviceColorPlaceholder(for: service.id)
                }
                
                // Service details
                VStack(alignment: .leading, spacing: 5) {
                    Text(service.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let description = service.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        Text(service.price)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button(action: {
                            showBookingSheet = true
                        }) {
                            Text("Book Now")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.blue)
                                .cornerRadius(15)
                        }
                    }
                }
                .padding()
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showBookingSheet) {
            BookingTimeSelectionView(viewModel: BookingViewModel(service: service))
        }
    }
    
    private func serviceColorPlaceholder(for serviceId: String) -> some View {
        ZStack {
            Rectangle()
                .fill(serviceColor(for: serviceId))
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
            
            Image(systemName: serviceSFSymbol(for: service.name))
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
    }
    
    // Helper functions from your existing code
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
    
    private func serviceColor(for serviceId: String) -> Color {
        let hash = serviceId.hash
        let colorIndex = abs(hash % 6)
        
        switch colorIndex {
        case 0: return .blue
        case 1: return .green
        case 2: return .orange
        case 3: return .purple
        case 4: return .red
        case 5: return .pink
        default: return .gray
        }
    }
}

class CategoryViewModel: ObservableObject {
    @Published var services: [Service] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    func fetchServices(forCategory categoryId: String) {
        isLoading = true
        services = []
        
        db.collection("services")
            .whereField("categoryId", isEqualTo: categoryId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("Error fetching services: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let snapshot = snapshot else { return }
                    
                    self?.services = snapshot.documents.compactMap { document in
                        return Service(document: document)
                    }
                }
            }
    }
}