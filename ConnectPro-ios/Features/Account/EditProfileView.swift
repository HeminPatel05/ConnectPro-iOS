import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditProfileView: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var profileImageURL: String = ""
    @State private var tempImageURL: String? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var selectedImageData: Data? = nil
    @State private var isLoading: Bool = true
    @State private var isUploadingImage: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showImagePicker: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    // Add environment object for data sharing between views
    @EnvironmentObject var userDataManager: UserDataManager
    
    private let db = Firestore.firestore()
    private let imgbbApiKey = "884c686bc032e5eb43069a6882155e63"
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading profile...")
            } else {
                Form {
                    Section(header: Text("Profile Picture")) {
                        HStack {
                            Spacer()
                            VStack {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else if let tempURL = tempImageURL, !tempURL.isEmpty {
                                    AsyncImage(url: URL(string: tempURL)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 120, height: 120)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipShape(Circle())
                                        case .failure:
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 120, height: 120)
                                                .foregroundColor(.gray)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else if !profileImageURL.isEmpty {
                                    AsyncImage(url: URL(string: profileImageURL)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 120, height: 120)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipShape(Circle())
                                        case .failure:
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 120, height: 120)
                                                .foregroundColor(.gray)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(.gray)
                                }
                                
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    Text("Change Photo")
                                        .foregroundColor(.blue)
                                }
                                .padding(.top, 8)
                                
                                if isUploadingImage {
                                    ProgressView("Uploading...")
                                        .padding(.top, 8)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    
                    Section(header: Text("Personal Information")) {
                        TextField("Full Name", text: $fullName)
                        // Email field is now displayed but not editable
                        Text(email)
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                        TextField("Phone Number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .onChange(of: phoneNumber) { newValue in
                                phoneNumber = formatPhoneNumber(newValue)
                            }
                    }
                    
                    Section {
                        Button(action: saveChanges) {
                            HStack {
                                Spacer()
                                Text("Save Changes")
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .disabled(isUploadingImage)
                    }
                }
                .navigationTitle("Edit Profile")
            }
        }
        .onAppear(perform: fetchUserData)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Profile Update"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("successfully") {
                        // Update parent view data
                        userDataManager.updateData()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
        .sheet(isPresented: $showImagePicker) {
            PhotoPicker(selectedImage: $selectedImage, selectedImageData: $selectedImageData)
        }
        .onChange(of: selectedImageData) { _ in
            if selectedImageData != nil {
                uploadImageToImgBB()
            }
        }
    }
    
    // MARK: - Data Fetching
    private func fetchUserData() {
        guard let currentUser = Auth.auth().currentUser else {
            alertMessage = "No user logged in"
            showAlert = true
            isLoading = false
            return
        }
        
        db.collection("userData").document(currentUser.uid).getDocument { document, error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Error fetching profile: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let document = document, document.exists else {
                alertMessage = "User profile not found"
                showAlert = true
                return
            }
            
            if let userData = document.data() {
                self.fullName = userData["fullName"] as? String ?? ""
                self.email = userData["email"] as? String ?? ""
                self.phoneNumber = userData["phoneNumber"] as? String ?? ""
                self.profileImageURL = userData["profilePicture"] as? String ?? ""
            }
        }
    }
    
    // MARK: - Image Upload
    private func uploadImageToImgBB() {
        guard let imageData = selectedImageData else { return }
        
        isUploadingImage = true
        
        let url = URL(string: "https://api.imgbb.com/1/upload?key=\(imgbbApiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isUploadingImage = false
                
                if let error = error {
                    self.alertMessage = "Upload failed: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let data = data else {
                    self.alertMessage = "No data received from server"
                    self.showAlert = true
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let dataDict = json["data"] as? [String: Any],
                       let imageUrl = dataDict["url"] as? String {
                        
                        // Store temporarily but don't update Firebase yet
                        self.tempImageURL = imageUrl
                    } else {
                        self.alertMessage = "Failed to parse server response"
                        self.showAlert = true
                    }
                } catch {
                    self.alertMessage = "Failed to parse response: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }.resume()
    }
    
    // MARK: - Firebase Updates
    private func saveChanges() {
        guard let currentUser = Auth.auth().currentUser else {
            alertMessage = "No user logged in"
            showAlert = true
            return
        }
        
        // Validate inputs
        if fullName.isEmpty || phoneNumber.isEmpty {
            alertMessage = "Please fill in all fields"
            showAlert = true
            return
        }
        
        // Validate phone number
        if !isValidPhoneNumber(phoneNumber) {
            alertMessage = "Please enter a valid phone number"
            showAlert = true
            return
        }
        
        // Prepare data to update
        var userData: [String: Any] = [
            "fullName": fullName,
            "phoneNumber": phoneNumber
        ]
        
        // Add new profile picture URL if we have one
        if let tempURL = tempImageURL {
            userData["profilePicture"] = tempURL
        }
        
        // Update Firestore with all changes at once
        db.collection("userData").document(currentUser.uid).updateData(userData) { error in
            if let error = error {
                alertMessage = "Error updating profile: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            alertMessage = "Profile updated successfully"
            showAlert = true
        }
    }
    
    // MARK: - Validation and Formatting
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let digitsOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return digitsOnly.count == 10
    }
    
    private func formatPhoneNumber(_ phone: String) -> String {
        let digitsOnly = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let truncatedDigits = String(digitsOnly.prefix(10))
        
        var formattedString = ""
        
        if truncatedDigits.count > 0 {
            let areaCode = truncatedDigits.prefix(min(3, truncatedDigits.count))
            formattedString = "(\(areaCode)"
            
            if truncatedDigits.count > 3 {
                let prefix = truncatedDigits.dropFirst(3).prefix(min(3, max(0, truncatedDigits.count - 3)))
                formattedString += ") \(prefix)"
                
                if truncatedDigits.count > 6 {
                    let number = truncatedDigits.dropFirst(6)
                    formattedString += "-\(number)"
                }
            }
        }
        
        return formattedString
    }
}

// MARK: - SwiftUI Photo Picker
struct PhotoPicker: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageData: Data?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ImagePicker(image: $selectedImage, imageData: $selectedImageData)
                
        }
    }
}

// MARK: - PhotosUI Integration
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var imageData: Data?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        guard let self = self, let image = image as? UIImage else { return }
                        
                        self.parent.image = image
                        self.parent.imageData = image.jpegData(compressionQuality: 0.8)
                    }
                }
            }
        }
    }
}

// MARK: - Data Manager for Sharing Data Between Views
class UserDataManager: ObservableObject {
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var profileImageURL: String = ""
    @Published var userId: String = ""
    @Published var userType: String = ""
    
    private let db = Firestore.firestore()
    
    init() {
        loadUserData()
    }
    
    func loadUserData() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        userId = currentUser.uid
        
        db.collection("userData").document(currentUser.uid).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            guard let document = document, document.exists, let userData = document.data() else { return }
            
            DispatchQueue.main.async {
                self.fullName = userData["fullName"] as? String ?? ""
                self.email = userData["email"] as? String ?? ""
                self.phoneNumber = userData["phoneNumber"] as? String ?? ""
                self.profileImageURL = userData["profilePicture"] as? String ?? ""
                self.userType = userData["userType"] as? String ?? ""
            }
        }
    }
    
    func updateData() {
        loadUserData()
    }
}
