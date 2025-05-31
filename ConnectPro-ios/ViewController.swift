import UIKit
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class ViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardDismissalOnTap()
        
        
        // Check if user is already logged in
        checkForExistingUser()
    }
    
    
    

    
    private func checkForExistingUser() {
        if let currentUser = Auth.auth().currentUser {
            // User is already logged in, proceed directly to the main app
            let email = currentUser.email ?? ""
            fetchUserDataAndNavigate(userId: currentUser.uid, email: email)
        }
    }
    
//    private func fetchUserDataAndNavigate(userId: String, email: String) {
//        print("Fetching user data for ID: \(userId)")
//        
//        let db = Firestore.firestore()
//        db.collection("userData").document(userId).getDocument { [weak self] document, error in
//            guard let self = self else { return }
//            
//            if let error = error {
//                print("Error fetching user data: \(error.localizedDescription)")
//                self.showAlert(message: "Error fetching user data: \(error.localizedDescription)")
//                self.navigateToMainApp(withEmail: email, profileImageURL: "", fullName: "", userId: userId)
//                return
//            }
//            
//            if let document = document, document.exists {
//                print("Document exists - data: \(document.data() ?? [:])")
//                if let userData = document.data() {
//                    let profileImageURL = userData["profilePicture"] as? String ?? ""
//                    let fullName = userData["fullName"] as? String ?? ""
//                    
//                    print("Retrieved profile image URL: \(profileImageURL)")
//                    print("Retrieved full name: \(fullName)")
//                    
//                    // Pass user data to the AccountView
//                    self.navigateToMainApp(withEmail: email, profileImageURL: profileImageURL, fullName: fullName, userId: userId)
//                } else {
//                    print("Document exists but data is nil")
//                    self.navigateToMainApp(withEmail: email, profileImageURL: "", fullName: "", userId: userId)
//                }
//            } else {
//                print("No document exists for user ID: \(userId)")
//                
//                // Create a new user document in Firestore
//                let userData: [String: Any] = [
//                    "email": email,
//                    "fullName": email.components(separatedBy: "@").first ?? "",
//                    "profilePicture": "https://i.ibb.co/pjr31LLy/image.jpg", // Default profile picture
//                    "createdAt": FieldValue.serverTimestamp()
//                ]
//                
//                db.collection("userData").document(userId).setData(userData) { error in
//                    if let error = error {
//                        print("Error creating user document: \(error.localizedDescription)")
//                    } else {
//                        print("Created new user document for ID: \(userId)")
//                    }
//                    self.navigateToMainApp(withEmail: email, profileImageURL: "https://i.ibb.co/pjr31LLy/image.jpg", fullName: email.components(separatedBy: "@").first ?? "", userId: userId)
//                }
//            }
//        }
//    }
//    
//    private func navigateToMainApp(withEmail email: String, profileImageURL: String, fullName: String = "", userId: String = "") {
//        let tabBarController = UITabBarController()
//        
//        // Create view controllers for each tab
//        let homeVC = UIHostingController(rootView: HomeView())
//        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
//        
//        let bookingsVC = UIHostingController(rootView: BookingsView())
//        bookingsVC.tabBarItem = UITabBarItem(title: "My Bookings", image: UIImage(systemName: "calendar"), tag: 1)
//        
//        // Pass user data directly to AccountView
//        let accountVC = UIHostingController(rootView: AccountView())
//        accountVC.tabBarItem = UITabBarItem(title: "Account", image: UIImage(systemName: "person"), tag: 2)
//
//
//        
//        // Set the view controllers for the tab bar
//        tabBarController.viewControllers = [homeVC, bookingsVC, accountVC]
//        
//        // Present the tab bar controller
//        tabBarController.modalPresentationStyle = .fullScreen
//        self.present(tabBarController, animated: true, completion: nil)
//    }
    
    private func fetchUserDataAndNavigate(userId: String, email: String) {
        print("Fetching user data for ID: \(userId)")
        
        let db = Firestore.firestore()
        db.collection("userData").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                self.showAlert(message: "Error fetching user data: \(error.localizedDescription)")
                self.navigateToMainApp(withEmail: email, profileImageURL: "", fullName: "", userType: "", userId: userId)
                return
            }
            
            if let document = document, document.exists {
                print("Document exists - data: \(document.data() ?? [:])")
                if let userData = document.data() {
                    let profileImageURL = userData["profilePicture"] as? String ?? ""
                    let fullName = userData["fullName"] as? String ?? ""
                    let userType = userData["userType"] as? String ?? ""
                    
                    print("Retrieved profile image URL: \(profileImageURL)")
                    print("Retrieved full name: \(fullName)")
                    print("Retrieved user type: \(userType)")
                    
                    // Pass user data to the AccountView
                    self.navigateToMainApp(withEmail: email, profileImageURL: profileImageURL, fullName: fullName, userType: userType, userId: userId)
                } else {
                    print("Document exists but data is nil")
                    self.navigateToMainApp(withEmail: email, profileImageURL: "", fullName: "", userType: "", userId: userId)
                }
            } else {
                print("No document exists for user ID: \(userId)")
                
                // Create a new user document in Firestore
                let userData: [String: Any] = [
                    "email": email,
                    "fullName": email.components(separatedBy: "@").first ?? "",
                    "profilePicture": "https://i.ibb.co/pjr31LLy/image.jpg", // Default profile picture
                    "userType": "Customer", // Default user type
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                db.collection("userData").document(userId).setData(userData) { error in
                    if let error = error {
                        print("Error creating user document: \(error.localizedDescription)")
                    } else {
                        print("Created new user document for ID: \(userId)")
                    }
                    self.navigateToMainApp(withEmail: email, profileImageURL: "https://i.ibb.co/pjr31LLy/image.jpg", fullName: email.components(separatedBy: "@").first ?? "", userType: "Customer", userId: userId)
                }
            }
        }
    }

    private func navigateToMainApp(withEmail email: String, profileImageURL: String, fullName: String = "", userType: String = "", userId: String = "") {
        let tabBarController = UITabBarController()
        
        // Create user data manager
        let userDataManager = UserDataManager()
        userDataManager.email = email
        userDataManager.profileImageURL = profileImageURL
        userDataManager.fullName = fullName
        userDataManager.userType = userType
        userDataManager.userId = userId
        
        // Initialize viewControllers array
        var viewControllers: [UIViewController] = []
        
        if userType == "Provider" {
            // For Provider: My Services, Bookings, Account (3 tabs only)
            let serviceManagementVC = UIHostingController(rootView: ServicesListView())
            serviceManagementVC.tabBarItem = UITabBarItem(title: "My Services", image: UIImage(systemName: "list.bullet.rectangle"), tag: 0)
            
            let providerBookingsVC = UIHostingController(rootView: ProviderBookingsView())
            providerBookingsVC.tabBarItem = UITabBarItem(title: "Your Bookings", image: UIImage(systemName: "calendar"), tag: 1)
            
            viewControllers.append(serviceManagementVC)
            viewControllers.append(providerBookingsVC)
        } else {
            // For Customer: Home, Bookings, Account
            let homeVC = UIHostingController(rootView: HomeView())
            homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
            
            let bookingsVC = UIHostingController(rootView: BookingsView())
            bookingsVC.tabBarItem = UITabBarItem(title: "My Bookings", image: UIImage(systemName: "calendar"), tag: 1)
            
            viewControllers.append(homeVC)
            viewControllers.append(bookingsVC)
        }
        
        // Account tab for all users (this will be the 3rd tab for providers)
        let accountVC = UIHostingController(rootView: AccountView())
        accountVC.tabBarItem = UITabBarItem(title: "Account", image: UIImage(systemName: "person"), tag: viewControllers.count)
        viewControllers.append(accountVC)
        
        // Set the view controllers for the tab bar
        tabBarController.viewControllers = viewControllers
        
        // Present the tab bar controller
        tabBarController.modalPresentationStyle = .fullScreen
        self.present(tabBarController, animated: true, completion: nil)
    }
    
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Show alert for empty fields
            showAlert(message: "Please enter both email and password")
            return
        }
        
        // Show loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.center = view.center
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        
        // Attempt Firebase authentication
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            // Hide loading indicator
            loadingIndicator.stopAnimating()
            loadingIndicator.removeFromSuperview()
            
            guard let self = self else { return }
            
            if let error = error {
                // Authentication failed
                self.showAlert(message: "Login failed: \(error.localizedDescription)")
                return
            }
            
            // Authentication successful
            if let userId = authResult?.user.uid {
                self.fetchUserDataAndNavigate(userId: userId, email: email)
            } else {
                self.navigateToMainApp(withEmail: email, profileImageURL: "", fullName: "", userId: "")
            }
        }
    }
    
    // Helper function to show alerts
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    

}

