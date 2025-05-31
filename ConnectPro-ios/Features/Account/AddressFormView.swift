//
//  AddressFormView.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/23/25.
//


import SwiftUI

struct AddressFormView: View {
    // Address to edit (nil if adding new)
    var address: AddressModel?
    var viewModel: AddressViewModel
    @Binding var isPresented: Bool
    
    // Form fields
    @State private var addressLine: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var isPrimary: Bool = false
    
    // Alert state
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Loading state
    @State private var isLoading = false
    
    private var isEditing: Bool {
        address != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Address Details")) {
                    TextField("Address Line", text: $addressLine)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zipCode)
                }
                
                Section {
                    Toggle("Set as Primary Address", isOn: $isPrimary)
                }
                
                Section {
                    Button(action: saveAddress) {
                        HStack {
                            Spacer()
                            Text(isLoading ? "Processing..." : (isEditing ? "Update Address" : "Add Address"))
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
            .navigationTitle(isEditing ? "Edit Address" : "Add Address")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                if let address = address {
                    // Populate form with existing address data
                    addressLine = address.address
                    city = address.city
                    state = address.state
                    zipCode = address.zipCode
                    isPrimary = address.isPrimary
                } else if viewModel.addresses.isEmpty {
                    // If this is the first address, make it primary by default
                    isPrimary = true
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !addressLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !zipCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveAddress() {
        isLoading = true
        
        // Create address model from form data
        let newAddress = AddressModel(
            id: address?.id ?? UUID().uuidString,
            address: addressLine,
            isPrimary: isPrimary,
            city: city,
            state: state,
            zipCode: zipCode
        )
        
        if isEditing {
            // Update existing address
            viewModel.updateAddress(newAddress) { success in
                isLoading = false
                
                if success {
                    isPresented = false
                } else {
                    alertTitle = "Error"
                    alertMessage = viewModel.errorMessage
                    showingAlert = true
                }
            }
        } else {
            // Add new address
            viewModel.addAddress(newAddress) { success in
                isLoading = false
                
                if success {
                    isPresented = false
                } else {
                    alertTitle = "Error"
                    alertMessage = viewModel.errorMessage
                    showingAlert = true
                }
            }
        }
    }
}
