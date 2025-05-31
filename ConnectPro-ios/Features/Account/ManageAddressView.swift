import SwiftUI

struct ManageAddressView: View {
    @StateObject private var viewModel = AddressViewModel()
    @State private var showingAddressForm = false
    @State private var addressToEdit: AddressModel?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.addresses) { address in
                    AddressRow(
                        address: address,
                        onEdit: {
                            addressToEdit = address
                            showingAddressForm = true
                        },
                        onDelete: {
                            deleteAddress(address)
                        },
                        onSetPrimary: {
                            setPrimaryAddress(address)
                        }
                    )
                }
                .onDelete(perform: deleteAddressAtOffsets)
            }
            .listStyle(InsetGroupedListStyle())
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Manage Addresses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    addressToEdit = nil
                    showingAddressForm = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                }
            }
        }
        .sheet(isPresented: $showingAddressForm) {
            AddressFormView(address: addressToEdit, viewModel: viewModel, isPresented: $showingAddressForm)
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            viewModel.loadAddresses()
        }
    }
    
    private func deleteAddressAtOffsets(offsets: IndexSet) {
        offsets.forEach { index in
            if index < viewModel.addresses.count {
                deleteAddress(viewModel.addresses[index])
            }
        }
    }
    
    private func deleteAddress(_ address: AddressModel) {
        viewModel.deleteAddress(id: address.id) { success in
            if !success {
                alertTitle = "Error"
                alertMessage = viewModel.errorMessage
                showingAlert = true
            }
        }
    }
    
    private func setPrimaryAddress(_ address: AddressModel) {
        viewModel.setAsPrimary(id: address.id) { success in
            if !success {
                alertTitle = "Error"
                alertMessage = viewModel.errorMessage
                showingAlert = true
            }
        }
    }
}

struct AddressRow: View {
    var address: AddressModel
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onSetPrimary: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(address.isPrimary ? "Primary Address" : "Address")
                        .font(.headline)
                    
                    if address.isPrimary {
                        Text("Default")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                
                Text(address.fullAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Context menu for more options
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                
                if !address.isPrimary {
                    Button(action: onSetPrimary) {
                        Label("Set as Primary", systemImage: "checkmark.circle")
                    }
                }
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            if !address.isPrimary {
                Button(action: onSetPrimary) {
                    Label("Set as Primary", systemImage: "checkmark.circle")
                }
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
