import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI


// View model to manage our services
class ServiceViewModel: ObservableObject {
    @Published var services: [Service] = []
    @Published var isAddingNewService = false
    @Published var isEditingService = false
    @Published var selectedService: Service?
    private var db = Firestore.firestore()
    private var currentUserId: String?
    @Published var categories: [Category] = []
    
    init() {
        // Setup Firebase Authentication listener to get current user ID
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUserId = user?.uid
            if let userId = user?.uid {
                self?.fetchServices(forProviderId: userId)
                self?.fetchCategories() // This line is crucial
            }
        }
        
        // You might also want to call fetchCategories unconditionally
        // in case you want to show categories even when no user is logged in
        fetchCategories()
    }
    
    func uploadImageToImgBB(_ imageData: Data, completion: @escaping (String?) -> Void) {
        let imgbbApiKey = "884c686bc032e5eb43069a6882155e63" // Use your API key from EditProfileView
        let url = URL(string: "https://api.imgbb.com/1/upload?key=\(imgbbApiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"service.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received from server")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let imageUrl = dataDict["url"] as? String {
                    
                    print("Image uploaded successfully: \(imageUrl)")
                    completion(imageUrl)
                } else {
                    print("Failed to parse server response")
                    completion(nil)
                }
            } catch {
                print("Failed to parse response: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    func fetchCategories() {
        print("Fetching categories...")
        db.collection("categories")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching categories: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found in categories collection")
                    return
                }
                
                print("Found \(documents.count) category documents")
                
                self?.categories = documents.compactMap { document in
                    print("Processing document: \(document.documentID)")
                    let category = Category(document: document)
                    print("Category created: \(category?.name ?? "nil")")
                    return category
                }
                
                print("Final categories count: \(self?.categories.count ?? 0)")
            }
    }
    
    func fetchServices(forProviderId providerId: String) {
        db.collection("services")
            .whereField("providerUserId", isEqualTo: providerId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching services: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.services = documents.compactMap { document in
                    Service(document: document)
                }
            }
    }
    

    func addService(name: String, rating: Double, price: String, image: String, imageUrl: String?, description: String?,
                    categoryId: String, isActive: Bool = true, startTime: Date? = nil, endTime: Date? = nil, workDays: [Int]? = nil) {
        guard let userId = currentUserId else {
            print("Error: No user is logged in")
            return
        }
        
        var newService: [String: Any] = [
            "name": name,
            "rating": rating,
            "price": "$" + price,
            "image": image,
            "imageUrl": imageUrl as Any,
            "description": description as Any,
            "categoryId": categoryId,
            "isActive": isActive,
            "providerUserId": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "isPopular": false
        ]
        
        // Add timing data if provided
        if let startTime = startTime {
            newService["startTime"] = Timestamp(date: startTime)
        }
        
        if let endTime = endTime {
            newService["endTime"] = Timestamp(date: endTime)
        }
        
        if let workDays = workDays {
            newService["workDays"] = workDays
        }
        
        db.collection("services").addDocument(data: newService) { error in
            if let error = error {
                print("Error adding service: \(error.localizedDescription)")
            }
        }
    }

    func updateService(service: Service, name: String, price: String, image: String, imageUrl: String?,
                      description: String?, categoryId: String, isActive: Bool,
                      startTime: Date? = nil, endTime: Date? = nil, workDays: [Int]? = nil) {
        var updatedData: [String: Any] = [
            "name": name,
            "price": price,
            "image": image,
            "imageUrl": imageUrl as Any,
            "description": description as Any,
            "categoryId": categoryId,
            "isActive": isActive,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Add timing data if provided
        if let startTime = startTime {
            updatedData["startTime"] = Timestamp(date: startTime)
        }
        
        if let endTime = endTime {
            updatedData["endTime"] = Timestamp(date: endTime)
        }
        
        if let workDays = workDays {
            updatedData["workDays"] = workDays
        }
        
        db.collection("services").document(service.id).updateData(updatedData) { error in
            if let error = error {
                print("Error updating service: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteService(at indexSet: IndexSet) {
        indexSet.forEach { index in
            let service = services[index]
            deleteService(service: service)
        }
    }
    
    func uploadImageData(_ data: Data, completion: @escaping (String?) -> Void) {
        guard let userId = currentUserId else {
            print("Error: No user is logged in")
            completion(nil)
            return
        }
        
        // Create a unique filename
        let filename = "\(userId)_\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child("service_images/\(filename)")
        
        // Upload the image data
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(data, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // Get the download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let url = url {
                    completion(url.absoluteString)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    func deleteService(service: Service) {
        // Option 1: Hard delete - remove the document
         db.collection("services").document(service.id).delete()
        
        // Option 2: Soft delete - update isActive to false
//        db.collection("services").document(service.id).updateData([
//            "isActive": false,
//            "updatedAt": FieldValue.serverTimestamp()
//        ]) { error in
//            if let error = error {
//                print("Error deleting service: \(error.localizedDescription)")
//            }
//        }
    }
}


// Main list view for services
struct ServicesListView: View {
    @StateObject private var viewModel = ServiceViewModel()
    @State private var showingAlert = false
    @State private var serviceToDelete: Service?
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.services.isEmpty {
                    VStack {
                        Text("No Services Available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Tap + to add your first service")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                } else {
                    List {
                        ForEach(viewModel.services) { service in
                            ServiceRow(service: service)
                                .contextMenu {
                                    Button {
                                        viewModel.selectedService = service
                                        viewModel.isEditingService = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        serviceToDelete = service
                                        showingAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        serviceToDelete = service
                                        showingAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                    
                                    Button {
                                        viewModel.selectedService = service
                                        viewModel.isEditingService = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
            .navigationTitle("My Services")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isAddingNewService = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isAddingNewService) {
                ServiceFormView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isEditingService) {
                if let service = viewModel.selectedService {
                    ServiceFormView(viewModel: viewModel, service: service)
                }
            }
            .alert("Confirm Deletion", isPresented: $showingAlert) {
                Button("Cancel", role: .cancel) {
                    serviceToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let service = serviceToDelete {
                        viewModel.deleteService(service: service)
                        serviceToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete this service?")
            }
        }
    }
}

// Row view for each service
struct ServiceRow: View {
    let service: Service
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(service.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(service.price)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .bold()
            }
            
            if let description = service.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            HStack {
                
                Spacer()
                
                if !service.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// Star rating view component
struct StarRatingView: View {
    let rating: Double
    let maxRating: Int = 5
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= Int(rating) ? "star.fill" :
                     (star == Int(rating) + 1 && rating.truncatingRemainder(dividingBy: 1) >= 0.5 ? "star.leadinghalf.fill" : "star"))
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.leading, 4)
        }
    }
}
