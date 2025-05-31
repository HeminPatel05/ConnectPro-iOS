import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

// Service form to add/edit services
struct ServiceFormView: View {
    @ObservedObject var viewModel: ServiceViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Form state
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var price: String = ""
    @State private var categoryId: String = ""
    @State private var isActive: Bool = true
    @State private var selectedImage: UIImage?
    @State private var imageData: Data?
    @State private var showingImagePicker = false
    @State private var isUploading = false
    
    // Time scheduling fields
    @State private var startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime: Date = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var workDays: Set<Int> = [1, 2, 3, 4, 5] // Monday to Friday by default
    
    
      
    private let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var service: Service?
    var isEditing: Bool {
        service != nil
    }
    
    init(viewModel: ServiceViewModel, service: Service? = nil) {
        self.viewModel = viewModel
        self.service = service
        
        if let service = service {
            _name = State(initialValue: service.name)
            _price = State(initialValue: service.price)
            _description = State(initialValue: service.description ?? "")
            _categoryId = State(initialValue: service.categoryId)
            _isActive = State(initialValue: service.isActive)
        }
        
        // Initialize time fields if available
        if let startTime = service?.startTime {
            _startTime = State(initialValue: startTime)
        }
        if let endTime = service?.endTime {
            _endTime = State(initialValue: endTime)
        }
        if let workDays = service?.workDays {
            _workDays = State(initialValue: Set(workDays))
        }
    }
    
    // Helper methods to break up complex expressions
    private func getImageView() -> some View {
        Group {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else if let imageUrl = service?.imageUrl, !imageUrl.isEmpty {
                AsyncImageView(urlString: imageUrl)
                    .frame(width: 120, height: 120)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
                    .frame(width: 120, height: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private func getCategoryPicker() -> some View {
        Group {
            if viewModel.categories.isEmpty {
                Text("Loading categories...")
                    .foregroundColor(.gray)
            } else {
                Picker("Category", selection: $categoryId) {
                    Text("Select Category").tag("")
                    ForEach(viewModel.categories) { category in
                        Text(category.name).tag(category.id)
                    }
                }
            }
        }
    }
    
    private func getUploadingOverlay() -> some View {
        Group {
            if isUploading {
                ZStack {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text("Uploading image...")
                            .foregroundColor(.white)
                    }
                    .frame(width: 150, height: 150)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private func handleSave() {
            isUploading = true
            

            
            // Convert time to timestamps
            let workDaysArray = Array(workDays).sorted()
            
            // If there's an image to upload, do that first
            if let imageData = imageData {
                viewModel.uploadImageToImgBB(imageData) { imageUrl in
                    DispatchQueue.main.async {
                        if isEditing, let service = service {
                            viewModel.updateService(
                                service: service,
                                name: name,
                                price: price,
                                image: "",
                                imageUrl: imageUrl,
                                description: description.isEmpty ? nil : description,
                                categoryId: categoryId,
                                isActive: isActive,
                                startTime: startTime,
                                endTime: endTime,
                                workDays: workDaysArray
                            )
                        } else {
                            viewModel.addService(
                                name: name,
                                rating: 0.0,
                                price: price,
                                image: "",
                                imageUrl: imageUrl,
                                description: description.isEmpty ? nil : description,
                                categoryId: categoryId,
                                isActive: isActive,
                                startTime: startTime,
                                endTime: endTime,
                                workDays: workDaysArray
                            )
                        }
                        
                        self.isUploading = false
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            } else {
                // No new image to upload
                if isEditing, let service = service {
                    viewModel.updateService(
                        service: service,
                        name: name,
                        price: price,
                        image: service.image,
                        imageUrl: service.imageUrl,
                        description: description.isEmpty ? nil : description,
                        categoryId: categoryId,
                        isActive: isActive,
                        startTime: startTime,
                        endTime: endTime,
                        workDays: workDaysArray
                    )
                } else {
                    viewModel.addService(
                        name: name,
                        rating: 0.0,
                        price: price,
                        image: "default_service",
                        imageUrl: nil,
                        description: description.isEmpty ? nil : description,
                        categoryId: categoryId,
                        isActive: isActive,
                        startTime: startTime,
                        endTime: endTime,
                        workDays: workDaysArray
                    )
                }
                
                isUploading = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    

    
    var body: some View {
        NavigationView {
            Form {
                
                // Service Image Section
                Section(header: Text("Service Image")) {
                    HStack {
                        Spacer()
                        getImageView()
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label(selectedImage != nil ? "Change Image" : "Select Image", systemImage: "photo.fill")
                    }
                }
                
                
                // Service Details Section
                Section(header: Text("Service Details")) {
                    TextField("Service Name", text: $name)
                    
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                    
                    // Description field
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Category picker
                    getCategoryPicker()
                    
                    Toggle("Active", isOn: $isActive)
                }
                
                Section(header: Text("Service Availability")) {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Work Days")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        ForEach(1..<8) { index in
                            Toggle(weekdays[index % 7], isOn: Binding(
                                get: { workDays.contains(index % 7) },
                                set: { newValue in
                                    if newValue {
                                        workDays.insert(index % 7)
                                    } else {
                                        workDays.remove(index % 7)
                                    }
                                }
                            ))
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Service" : "Add Service")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    handleSave()
                }
                .disabled(name.isEmpty || price.isEmpty || categoryId.isEmpty || isUploading)
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, imageData: $imageData)
            }
            .overlay(getUploadingOverlay())
        }
    }
}

// MARK: - PhotosUI Integration

// AsyncImage view for loading images from URL
struct AsyncImageView: View {
    let urlString: String
    @State private var image: UIImage? = nil
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let downloadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = downloadedImage
                }
            }
        }.resume()
    }
}
