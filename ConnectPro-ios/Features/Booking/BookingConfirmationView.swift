import SwiftUI
import FirebaseAuth
import FirebaseFirestore



struct BookingConfirmationView: View {
    @Environment(\.presentationMode) var presentationMode
    let service: Service
    let date: String
    let timeSlot: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding(.top, 30)
            
            // Confirmation Text
            Text("Booking Confirmed!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your booking has been successfully placed.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Booking Details
            VStack(spacing: 15) {
                bookingDetailRow(title: "Service", value: service.name)
                bookingDetailRow(title: "Price", value: service.price)
                bookingDetailRow(title: "Date", value: date)
                bookingDetailRow(title: "Time", value: timeSlot)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Instructions
            Text("You'll receive a confirmation with more details shortly. The service provider will contact you if there are any changes.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
            .padding()
        }
        .padding(.bottom, 20)
    }
    
    private func bookingDetailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
