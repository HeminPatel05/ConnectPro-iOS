import SwiftUI
import FirebaseFirestore
import FirebaseAuth


struct BookingTimeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BookingViewModel
    
    // For date picker
    @State private var selectedDate = Date()
    
    // Grid layout
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Date & Time")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                        .padding()
                }
            }
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Date selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Date")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .onChange(of: selectedDate) { newDate in
                                viewModel.clearSlots()
                                viewModel.fetchAvailableSlots(for: newDate)
                            }
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Address selection section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Service Address")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if viewModel.isLoadingAddresses {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .padding(.horizontal)
                        } else if viewModel.userAddresses.isEmpty {
                            VStack(alignment: .center, spacing: 8) {
                                Text("No addresses found")
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    // Add logic to navigate to add address screen
                                    print("Navigate to add address")
                                }) {
                                    Text("+ Add New Address")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .padding(.horizontal)
                        } else {
                            ForEach(viewModel.userAddresses) { address in
                                addressSelectionButton(address: address)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Time slots
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Time Slots")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if viewModel.isLoadingSlots {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 100)
                        } else if viewModel.availableSlots.isEmpty {
                            Text("No slots available for this date. Please try another date.")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
                                .padding(.horizontal)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(viewModel.availableSlots, id: \.self) { slot in
                                    timeSlotButton(slot: slot)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Provider's availability notes (if any)
                    if !viewModel.providerNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Provider Notes")
                                .font(.headline)
                            
                            Text(viewModel.providerNotes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                    
                    // Spacer to ensure scroll works properly
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            
            // Bottom button
            VStack {
                Button(action: {
                    viewModel.confirmBooking()
                }) {
                    Text("Confirm Booking")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isButtonEnabled ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isButtonEnabled)
                .padding()
            }
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
        }
        .background(Color(.systemGray6))
        .onAppear {
            viewModel.fetchAvailableSlots(for: selectedDate)
            viewModel.fetchUserAddresses()
        }
        .fullScreenCover(isPresented: $viewModel.showingConfirmation) {
            BookingConfirmationView(
                service: viewModel.service,
                date: viewModel.formattedDate,
                timeSlot: viewModel.selectedSlot
            )
        }
        .onDisappear {
            // Refresh available slots when returning from confirmation
            viewModel.fetchAvailableSlots(for: viewModel.selectedDate)
            // Clear selection
            viewModel.selectedSlot = ""
        }
    }
    
    // Check if button should be enabled - needs both time slot and address
    private var isButtonEnabled: Bool {
        return !viewModel.selectedSlot.isEmpty && viewModel.selectedAddressId != nil
    }
    
    // Address selection button
    private func addressSelectionButton(address: UserAddress) -> some View {
        Button(action: {
            viewModel.selectedAddressId = address.id
        }) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(address.address)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("\(address.city), \(address.state) \(address.zipCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if address.isPrimary {
                        Text("Primary")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                if viewModel.selectedAddressId == address.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        viewModel.selectedAddressId == address.id ? Color.blue : Color.gray.opacity(0.3),
                        lineWidth: viewModel.selectedAddressId == address.id ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeSlotButton(slot: String) -> some View {
        Button(action: {
            viewModel.selectedSlot = viewModel.selectedSlot == slot ? "" : slot
        }) {
            Text(slot)
                .font(.subheadline)
                .foregroundColor(viewModel.selectedSlot == slot ? .white : .primary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(viewModel.selectedSlot == slot ? Color.blue : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .cornerRadius(8)
        }
    }
}


class BookingViewModel: ObservableObject {
    let service: Service
    @Published var availableSlots: [String] = []
    @Published var selectedSlot: String = ""
    @Published var isLoadingSlots: Bool = false
    @Published var providerNotes: String = ""
    @Published var showingConfirmation: Bool = false
    @Published var selectedDate: Date = Date()
    @Published var formattedDate: String = ""
    
    // Address-related properties
    @Published var userAddresses: [UserAddress] = []
    @Published var selectedAddressId: String? = nil
    @Published var isLoadingAddresses: Bool = false
    
    private var db = Firestore.firestore()
    
    init(service: Service) {
        self.service = service
    }
    
    // Fetch user addresses from Firebase
    func fetchUserAddresses() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        isLoadingAddresses = true
        
        db.collection("userData").document(userId).collection("addresses")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoadingAddresses = false
                
                if let error = error {
                    print("Error fetching addresses: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No address documents found")
                    return
                }
                
                self.userAddresses = documents.compactMap { document in
                    let id = document.documentID
                    let data = document.data()
                    return UserAddress(id: id, data: data)
                }
                
                print("Fetched \(self.userAddresses.count) addresses")
                
                // Sort addresses so primary is first
                self.userAddresses.sort { $0.isPrimary && !$1.isPrimary }
                
                // Auto-select the primary address if available, otherwise first one
                if let primaryAddress = self.userAddresses.first(where: { $0.isPrimary }) {
                    self.selectedAddressId = primaryAddress.id
                } else if !self.userAddresses.isEmpty {
                    self.selectedAddressId = self.userAddresses.first?.id
                }
            }
    }
    
    func clearSlots() {
        // Immediately clear available slots when date changes
        self.availableSlots = []
        self.selectedSlot = ""
    }
    
    func fetchAvailableSlots(for date: Date) {
        isLoadingSlots = true
        availableSlots = []
        selectedSlot = ""
        selectedDate = date
        
        // Format the date for queries and display
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        formattedDate = displayFormatter.string(from: date)
        
        // Check if the service is available on this day of the week
        let calendar = Calendar.current
        var weekday = calendar.component(.weekday, from: date) // Standard weekday (1 = Sunday)
        
        // Convert to your system where Monday = 1, Sunday = 7
        if weekday == 1 {
            weekday = 7 // Convert Sunday from 1 to 7
        } else {
            weekday = weekday - 1 // Shift others down by 1
        }
        
        print("Selected day index (where Monday=1): \(weekday)")
        print("Service workDays: \(service.workDays ?? [])")
        
        // Check if this service is available on selected day
        if let workDays = service.workDays, workDays.contains(weekday) {
            print("Service is available on this day! Proceeding to check time slots.")
            
            // Check existing bookings
            fetchExistingBookings(on: dateString) { [weak self] bookedSlots in
                guard let self = self else { return }
                
                if let startTime = self.service.startTime, let endTime = self.service.endTime {
                    // Debug time components
                    let calendar = Calendar.current
                    let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                    let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
                    
                    print("Service time range: \(startComponents.hour ?? 0):\(startComponents.minute ?? 0) to \(endComponents.hour ?? 0):\(endComponents.minute ?? 0)")
                    
                    // Generate available time slots
                    self.generateTimeSlots(
                        startHour: startComponents.hour ?? 9,
                        startMinute: startComponents.minute ?? 0,
                        endHour: endComponents.hour ?? 17,
                        endMinute: endComponents.minute ?? 0,
                        bookedSlots: bookedSlots
                    )
                    
                    if self.availableSlots.isEmpty {
                        if bookedSlots.isEmpty {
                            self.providerNotes = "No time slots available for this service on this date."
                        } else {
                            self.providerNotes = "All slots are already booked for this date. Please try another date."
                        }
                    } else {
                        self.providerNotes = "Service duration: 1 hour"
                    }
                } else {
                    print("Service doesn't have startTime or endTime")
                    self.providerNotes = "Provider hasn't set specific hours. Please contact for details."
                }
                
                self.isLoadingSlots = false
            }
        } else {
            print("Service not available on this day")
            self.providerNotes = "This service is not available on this day. Please select another date."
            self.isLoadingSlots = false
        }
    }
    
    private func fetchExistingBookings(on dateString: String, completion: @escaping ([String]) -> Void) {
        // Ensure we have a provider ID
        guard let providerId = service.providerUserId else {
            print("No provider ID found for service")
            completion([])
            return
        }
        
        // Query Firebase for existing bookings on this date for this service
        db.collection("bookings")
            .whereField("serviceId", isEqualTo: service.id)
            .whereField("date", isEqualTo: dateString)
            .whereField("status", in: ["pending", "confirmed"]) // Only consider active bookings
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching bookings: \(error)")
                    completion([])
                    return
                }
                
                // Extract booked time slots
                let bookedSlots = snapshot?.documents.compactMap { document -> String? in
                    let data = document.data()
                    return data["timeSlot"] as? String
                } ?? []
                
                print("Found \(bookedSlots.count) existing bookings for this date")
                completion(bookedSlots)
            }
    }
    
    private func generateTimeSlots(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, bookedSlots: [String] = []) {
        // Clear existing slots
        availableSlots = []
        
        // Create a formatter for the time slots
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        // Create calendar and components
        let calendar = Calendar.current
        
        // Use current date as base (we only care about time)
        let baseDate = calendar.startOfDay(for: Date())
        
        // Generate the time slots
        if let startDate = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: baseDate) {
            var currentSlotStart = startDate
            
            // End time components
            let endDate = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: baseDate) ?? baseDate
            
            print("Generating slots from \(formatter.string(from: startDate)) to \(formatter.string(from: endDate))")
            
            // Generate slots until we reach the end time
            while currentSlotStart < endDate {
                // Only add if the slot end time is before the service end time
                if let slotEndTime = calendar.date(byAdding: .hour, value: 1, to: currentSlotStart),
                   slotEndTime <= endDate {
                    let slotString = formatter.string(from: currentSlotStart)
                    
                    // Only add the slot if it's not already booked
                    if !bookedSlots.contains(slotString) {
                        availableSlots.append(slotString)
                        print("Added available slot: \(slotString)")
                    } else {
                        print("Slot already booked: \(slotString)")
                    }
                }
                
                // Move to next slot start (90 minutes from previous slot start - 1 hour service + 30 min gap)
                if let nextSlot = calendar.date(byAdding: .minute, value: 90, to: currentSlotStart) {
                    currentSlotStart = nextSlot
                } else {
                    break
                }
            }
            
            print("Generated \(availableSlots.count) available time slots")
        }
    }
    
    func confirmBooking() {
        guard !selectedSlot.isEmpty,
              let addressId = selectedAddressId,
              let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Get the selected address
        let selectedAddress = userAddresses.first(where: { $0.id == addressId })
        
        // Format the date for booking
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDateStr = dateFormatter.string(from: selectedDate)
        
        // Create booking in Firebase
        let bookingRef = db.collection("bookings").document()
        
        // Create booking data
        var bookingData: [String: Any] = [
            "id": bookingRef.documentID,
            "userId": userId,
            "serviceId": service.id,
            "serviceName": service.name,
            "servicePrice": service.price,
            "providerUserId": service.providerUserId ?? "",
            "date": selectedDateStr,
            "timeSlot": selectedSlot,
            "status": "pending",
            "addressId": addressId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Add address details if available
        if let address = selectedAddress {
            bookingData["addressDetails"] = [
                "address": address.address,
                "city": address.city,
                "state": address.state,
                "zipCode": address.zipCode
            ]
        }
        
        bookingRef.setData(bookingData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error adding booking: \(error)")
            } else {
                print("Booking successfully created")
                
                let bookedSlot = self.selectedSlot
                self.availableSlots.removeAll { $0 == bookedSlot }
                
                DispatchQueue.main.async {
                    self.showingConfirmation = true
                }
            }
        }
    }
}
