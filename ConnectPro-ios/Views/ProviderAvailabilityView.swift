//
//  ProviderAvailabilityView.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/23/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProviderAvailabilityView: View {
    @StateObject private var viewModel = ProviderAvailabilityViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // For date picker
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                // Date picker for selecting the day to set availability
                DatePicker("Select Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .onChange(of: selectedDate) { newDate in
                        viewModel.loadAvailabilityForDate(newDate)
                    }
                
                // Time slot configuration section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Configure Available Time Slots")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Business hours picker
                    HStack {
                        Text("Business Hours:")
                            .font(.subheadline)
                        
                        Picker("Start Time", selection: $viewModel.startHour) {
                            ForEach(6..<20, id: \.self) { hour in
                                Text("\(hour):00")
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("to")
                        
                        Picker("End Time", selection: $viewModel.endHour) {
                            ForEach(viewModel.startHour + 1...23, id: \.self) { hour in
                                Text("\(hour):00")
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    // Slot duration
                    HStack {
                        Text("Appointment Duration:")
                            .font(.subheadline)
                        
                        Picker("Duration", selection: $viewModel.slotDuration) {
                            Text("30 minutes").tag(30)
                            Text("45 minutes").tag(45)
                            Text("60 minutes").tag(60)
                            Text("90 minutes").tag(90)
                            Text("120 minutes").tag(120)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    // Break time between appointments
                    HStack {
                        Text("Break Between Appointments:")
                            .font(.subheadline)
                        
                        Picker("Break", selection: $viewModel.breakTime) {
                            Text("None").tag(0)
                            Text("5 minutes").tag(5)
                            Text("10 minutes").tag(10)
                            Text("15 minutes").tag(15)
                            Text("30 minutes").tag(30)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    // Generate button
                    Button(action: {
                        viewModel.generateTimeSlots()
                    }) {
                        Text("Generate Time Slots")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding()
                
                // Display generated time slots with toggle switches
                VStack(alignment: .leading, spacing: 16) {
                    Text("Available Time Slots")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 100)
                    } else if viewModel.generatedSlots.isEmpty {
                        Text("Generate time slots to configure availability")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(viewModel.generatedSlots, id: \.self) { slot in
                                    HStack {
                                        Text(slot)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: binding(for: slot))
                                            .labelsHidden()
                                    }
                                    .padding(.horizontal)
                                    
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                    
                    // Notes field
                    VStack(alignment: .leading) {
                        Text("Additional Notes for Customers:")
                            .font(.subheadline)
                        
                        TextEditor(text: $viewModel.providerNotes)
                            .frame(height: 80)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Save button
                    Button(action: {
                        viewModel.saveAvailability()
                    }) {
                        Text("Save Availability")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding()
            }
            .navigationTitle("Set Availability")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .background(Color(.systemGray6))
            .onAppear {
                viewModel.loadAvailabilityForDate(selectedDate)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // Helper function to create bindings for each time slot toggle
    private func binding(for slot: String) -> Binding<Bool> {
        Binding<Bool>(
            get: { viewModel.selectedSlots.contains(slot) },
            set: { isSelected in
                if isSelected {
                    viewModel.selectedSlots.insert(slot)
                } else {
                    viewModel.selectedSlots.remove(slot)
                }
            }
        )
    }
}

class ProviderAvailabilityViewModel: ObservableObject {
    @Published var startHour: Int = 9
    @Published var endHour: Int = 17
    @Published var slotDuration: Int = 60
    @Published var breakTime: Int = 15
    
    @Published var generatedSlots: [String] = []
    @Published var selectedSlots: Set<String> = []
    @Published var providerNotes: String = ""
    
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    
    private var selectedDate: Date = Date()
    private var db = Firestore.firestore()
    
    func loadAvailabilityForDate(_ date: Date) {
        isLoading = true
        selectedDate = date
        generatedSlots = []
        selectedSlots = []
        
        guard let providerId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        // Format the date for querying
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Fetch existing availability from Firestore
        db.collection("providers").document(providerId).collection("availability").document(dateString).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let document = document, document.exists, let data = document.data() {
                    // Load saved settings
                    self.startHour = data["startHour"] as? Int ?? 9
                    self.endHour = data["endHour"] as? Int ?? 17
                    self.slotDuration = data["slotDuration"] as? Int ?? 60
                    self.breakTime = data["breakTime"] as? Int ?? 15
                    self.providerNotes = data["notes"] as? String ?? ""
                    
                    // Load saved slots
                    if let slots = data["slots"] as? [String], let available = data["availableSlots"] as? [String] {
                        self.generatedSlots = slots
                        self.selectedSlots = Set(available)
                    } else {
                        // Generate default slots if none saved
                        self.generateTimeSlots()
                    }
                } else {
                    // No settings found, use defaults
                    self.generateTimeSlots()
                }
                
                self.isLoading = false
            }
        }
    }
    
    func generateTimeSlots() {
        var slots: [String] = []
        
        // Ensure end hour is after start hour
        if endHour <= startHour {
            endHour = startHour + 1
        }
        
        // Calculate total minutes in work day
        let startMinutes = startHour * 60
        let endMinutes = endHour * 60
        
        // Calculate slot interval (duration + break)
        let slotInterval = slotDuration + breakTime
        
        // Generate slots
        var currentMinute = startMinutes
        while currentMinute + slotDuration <= endMinutes {
            let hour = currentMinute / 60
            let minute = currentMinute % 60
            
            let nextMinute = currentMinute + slotDuration
            let nextHour = nextMinute / 60
            let nextMinuteRemainder = nextMinute % 60
            
            // Format time slot string (e.g., "9:00 AM - 10:00 AM")
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            
            var startComponents = DateComponents()
            startComponents.hour = hour
            startComponents.minute = minute
            
            var endComponents = DateComponents()
            endComponents.hour = nextHour
            endComponents.minute = nextMinuteRemainder
            
            if let startTime = calendar.date(from: startComponents),
               let endTime = calendar.date(from: endComponents) {
                let slotString = "\(timeFormatter.string(from: startTime)) - \(timeFormatter.string(from: endTime))"
                slots.append(slotString)
            }
            
            // Move to next slot
            currentMinute += slotInterval
        }
        
        generatedSlots = slots
        
        // By default, select all generated slots as available
        selectedSlots = Set(slots)
    }
    
    func saveAvailability() {
        guard let providerId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "You must be signed in to save availability.")
            return
        }
        
        // Format the date for saving
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        // Prepare data for Firestore
        let data: [String: Any] = [
            "startHour": startHour,
            "endHour": endHour,
            "slotDuration": slotDuration,
            "breakTime": breakTime,
            "slots": generatedSlots,
            "availableSlots": Array(selectedSlots),
            "notes": providerNotes,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Save to Firestore
        db.collection("providers").document(providerId).collection("availability").document(dateString).setData(data) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "Error", message: "Failed to save availability: \(error.localizedDescription)")
                } else {
                    self.showAlert(title: "Success", message: "Your availability has been saved.")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
