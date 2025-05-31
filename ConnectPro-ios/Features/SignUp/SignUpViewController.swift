//
//  SignUpViewController.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/20/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var userType: UISegmentedControl!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    
    // Reference to Firestore database
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupKeyboardDismissalOnTap()
    }
    
    @IBAction func signUpButtonTapped(_ sender: Any) {
        // 1. Validate input fields
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(message: "Please enter an email address")
            return
        }
        
        guard let fullName = fullNameTextField.text, !fullName.isEmpty else {
            showAlert(message: "Please enter your full name")
            return
        }
        
        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter a password")
            return
        }
        
        guard let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(message: "Please confirm your password")
            return
        }
        
        guard let phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty else {
            showAlert(message: "Please enter your phone number")
            return
        }
        
        // 2. Validate email format
        if !isValidEmail(email) {
            showAlert(message: "Please enter a valid email address")
            return
        }
        
        // 3. Check if passwords match
        if password != confirmPassword {
            showAlert(message: "Passwords do not match")
            return
        }
        
        // 4. Validate password strength
        if !isValidPassword(password) {
            showAlert(message: "Password must be at least 8 characters and contain uppercase, lowercase, and a number")
            return
        }
        
        // 6. Proceed with signup process
        // Show loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        // Get user type (0 = Customer, 1 = Service Provider)
        let userTypeValue = userType.selectedSegmentIndex == 0 ? "Customer" : "Provider"
        
        // Create user with Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            // Hide loading indicator
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
            }
            
            if let error = error {
                // Handle error
                self.showAlert(message: "Error creating account: \(error.localizedDescription)")
                return
            }
            
            guard let user = authResult?.user else {
                self.showAlert(message: "Unknown error occurred")
                return
            }
            
            // Successfully created user, now store additional user data in Firestore
            let userData: [String: Any] = [
                "email": email,
                "fullName": fullName,
                "phoneNumber": phoneNumber,
                "userType": userTypeValue,
                "profilePicture": "https://ibb.co/5hx51RRF", // Default profile picture URL
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            // Add user data to Firestore
            self.db.collection("userData").document(user.uid).setData(userData) { error in
                if let error = error {
                    self.showAlert(message: "Error saving user data: \(error.localizedDescription)")
                    return
                }
                
                // Handle successful signup
                self.showAlert(message: "Sign up successful!") { [weak self] _ in
                    // Navigate to the next screen or login
                    self?.dismiss(animated: true, completion: nil)
                    // Or perform segue to appropriate screen based on user type
                    // let segueIdentifier = userTypeValue == "Customer" ? "goToCustomerHome" : "goToProviderHome"
                    // self?.performSegue(withIdentifier: segueIdentifier, sender: self)
                }
            }
        }
    }

    // Add this new helper method to validate phone numbers
//    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
//        // Basic US phone number validation (10 digits, allowing different formats)
//        let phoneRegex = "^\\(?([0-9]{3})\\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$"
//        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
//        return phonePredicate.evaluate(with: phoneNumber)
//    }

    // Helper method to validate email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // Helper method to validate password strength
    private func isValidPassword(_ password: String) -> Bool {
        // Password must be at least 8 characters long
        guard password.count >= 8 else { return false }
        
        // Check for at least one uppercase letter
        let uppercaseRegex = ".*[A-Z]+.*"
        let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
        guard uppercasePredicate.evaluate(with: password) else { return false }
        
        // Check for at least one lowercase letter
        let lowercaseRegex = ".*[a-z]+.*"
        let lowercasePredicate = NSPredicate(format: "SELF MATCHES %@", lowercaseRegex)
        guard lowercasePredicate.evaluate(with: password) else { return false }
        
        // Check for at least one digit
        let digitRegex = ".*[0-9]+.*"
        let digitPredicate = NSPredicate(format: "SELF MATCHES %@", digitRegex)
        guard digitPredicate.evaluate(with: password) else { return false }
        
        return true
    }

    // Helper method to show alerts
    private func showAlert(message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: "ConnectPro", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
        present(alert, animated: true, completion: nil)
    }
}
