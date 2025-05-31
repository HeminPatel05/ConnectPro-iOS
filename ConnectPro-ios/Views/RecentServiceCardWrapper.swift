//
//  RecentServiceCardWrapper.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/25/25.
//
import SwiftUI
import FirebaseFirestore

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
            print("📱 Card appeared for: \(recentService.name) (viewed \(recentService.lastViewedFormatted))")
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
                    
                    // Display the formatted time
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
        
        print("🔍 Fetching service details for: \(recentService.serviceId)")
        
        // Try to fetch the service from Firestore
        let db = Firestore.firestore()
        db.collection("services").document(recentService.serviceId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("❌ Error fetching service: \(error.localizedDescription)")
                    return
                }
                
                if let document = snapshot, document.exists {
                    if let documentSnapshot = document as? QueryDocumentSnapshot {
                        if let service = Service(document: documentSnapshot) {
                            self.service = service
                            print("✅ Loaded service details: \(service.name)")
                        } else {
                            print("❌ Failed to parse service from document")
                        }
                    } else {
                        print("❌ Document is not a QueryDocumentSnapshot")
                    }
                } else {
                    print("❌ Document doesn't exist for ID: \(recentService.serviceId)")
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
