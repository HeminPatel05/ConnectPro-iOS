import SwiftUI

struct BookingCardView: View {
    let booking: Booking
    @ObservedObject var viewModel: BookingsViewModel
    let onRebook: () -> Void
    let onCancel: () -> Void
    let onRate: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Service Info Row
            HStack {
                Text(booking.serviceName)
                    .font(.headline)
                Spacer()
                StatusBadge(status: booking.status)
            }
            
            Divider()
            
            // Details Section
            VStack(alignment: .leading, spacing: 8) {
                // Date and Time Slot
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    VStack(alignment: .leading) {
                        Text("\(formattedDate) at \(booking.timeSlot)")
                            .font(.subheadline)
                    
                    }
                }
                
                // Price
                if let price = booking.price {
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(.gray)
                        Text(price)
                            .font(.subheadline)
                    }
                }
                
                // Address from addressDetails
                if let formattedAddress = booking.getFormattedAddress() {
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.gray)
                        Text(formattedAddress)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                } else if let location = booking.location {
                    // Fallback to location if addressDetails not available
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.gray)
                        Text(location)
                            .font(.subheadline)
                    }
                }
                
                // For completed bookings, show provider contact info
                if booking.status == .completed, let providerUserId = booking.providerName {
                    let fullName = viewModel.getUserInfo(for: providerUserId, infoType: "fullName")
                    if !fullName.isEmpty {
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.gray)
                            Text("Provider: \(fullName)")
                                .font(.subheadline)
                        }
                    }
                    
                    let email = viewModel.getUserInfo(for: providerUserId, infoType: "email")
                    if !email.isEmpty {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.gray)
                            Text("Email: \(email)")
                                .font(.subheadline)
                        }
                    }
                    
                    let contact = viewModel.getUserInfo(for: providerUserId, infoType: "contact")
                    if !contact.isEmpty {
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.gray)
                            Text("Contact: \(contact)")
                                .font(.subheadline)
                        }
                    }
                }
            }
            
            // Action Buttons based on status
            HStack {
                Spacer()
                
                // Only show Cancel button for pending or confirmed bookings
                if booking.status == .pending || booking.status == .confirmed {
                    // Cancel button for upcoming bookings
                    Button(action: onCancel) {
                        Text("Cancel")
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                // Removed rating stars for completed bookings
                // Removed "Book Again" button for completed and cancelled bookings
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // Date formatter - Modified to only show the date without time
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none // Changed to none to not show the time here
        return formatter.string(from: booking.date)
    }
}
