//
//  AddressModel 2.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/23/25.
//


//
//  AddressModel.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/23/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// Model for storing address information
struct AddressModel: Identifiable, Codable {
    var id: String = UUID().uuidString
    var address: String
    var isPrimary: Bool = false
    var city: String
    var state: String
    var zipCode: String
    
    // Full formatted address for display
    var fullAddress: String {
        return "\(address), \(city), \(state) \(zipCode)"
    }
}

// ViewModel to handle Firebase operations
class AddressViewModel: ObservableObject {
    @Published var addresses: [AddressModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private var db = Firestore.firestore()
    
    // Get current user ID
    private var userId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // Reference to the user's addresses collection
    private var addressesRef: CollectionReference? {
        guard let userId = userId else { return nil }
        return db.collection("userData").document(userId).collection("addresses")
    }
    
    // Load all addresses for the current user
    func loadAddresses() {
        guard let addressesRef = addressesRef else {
            self.errorMessage = "User not logged in"
            return
        }
        
        isLoading = true
        
        addressesRef.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error loading addresses: \(error.localizedDescription)"
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                self.errorMessage = "No addresses found"
                return
            }
            
            self.addresses = documents.compactMap { document -> AddressModel? in
                do {
                    var address = try document.data(as: AddressModel.self)
                    address.id = document.documentID
                    return address
                } catch {
                    self.errorMessage = "Error decoding address: \(error.localizedDescription)"
                    return nil
                }
            }
        }
    }
    
    // Add a new address
    func addAddress(_ address: AddressModel, completion: @escaping (Bool) -> Void) {
        guard let addressesRef = addressesRef else {
            self.errorMessage = "User not logged in"
            completion(false)
            return
        }
        
        // If this is set as primary, update all other addresses to non-primary
        if address.isPrimary {
            updatePrimaryStatus(for: address.id)
        }
        
        do {
            _ = try addressesRef.addDocument(from: address) { error in
                if let error = error {
                    self.errorMessage = "Error adding address: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                completion(true)
            }
        } catch {
            self.errorMessage = "Error adding address: \(error.localizedDescription)"
            completion(false)
        }
    }
    
    // Update an existing address
    func updateAddress(_ address: AddressModel, completion: @escaping (Bool) -> Void) {
        guard let addressesRef = addressesRef else {
            self.errorMessage = "User not logged in"
            completion(false)
            return
        }
        
        // If this is set as primary, update all other addresses to non-primary
        if address.isPrimary {
            updatePrimaryStatus(for: address.id)
        }
        
        do {
            try addressesRef.document(address.id).setData(from: address) { error in
                if let error = error {
                    self.errorMessage = "Error updating address: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                completion(true)
            }
        } catch {
            self.errorMessage = "Error updating address: \(error.localizedDescription)"
            completion(false)
        }
    }
    
    // Delete an address
    func deleteAddress(id: String, completion: @escaping (Bool) -> Void) {
        guard let addressesRef = addressesRef else {
            self.errorMessage = "User not logged in"
            completion(false)
            return
        }
        
        // Check if this is the primary address
        let isPrimary = addresses.first(where: { $0.id == id })?.isPrimary ?? false
        
        addressesRef.document(id).delete { error in
            if let error = error {
                self.errorMessage = "Error deleting address: \(error.localizedDescription)"
                completion(false)
                return
            }
            
            // If we deleted the primary address and have other addresses, make another one primary
            if isPrimary && !self.addresses.isEmpty {
                if let firstAddress = self.addresses.first(where: { $0.id != id }) {
                    var updatedAddress = firstAddress
                    updatedAddress.isPrimary = true
                    self.updateAddress(updatedAddress) { _ in }
                }
            }
            
            completion(true)
        }
    }
    
    // Set an address as primary
    func setAsPrimary(id: String, completion: @escaping (Bool) -> Void) {
        updatePrimaryStatus(for: id)
        
        guard let addressesRef = addressesRef else {
            self.errorMessage = "User not logged in"
            completion(false)
            return
        }
        
        addressesRef.document(id).updateData(["isPrimary": true]) { error in
            if let error = error {
                self.errorMessage = "Error setting address as primary: \(error.localizedDescription)"
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    // Helper method to update primary status
    private func updatePrimaryStatus(for newPrimaryId: String) {
        guard let addressesRef = addressesRef else { return }
        
        // Find current primary address
        if let currentPrimary = addresses.first(where: { $0.isPrimary && $0.id != newPrimaryId }) {
            // Update it to non-primary
            addressesRef.document(currentPrimary.id).updateData(["isPrimary": false])
        }
    }
}
