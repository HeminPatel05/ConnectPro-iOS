import SwiftUI

struct ProviderBookingsView: View {
    @StateObject private var viewModel = ProviderBookingsViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading bookings...")
                } else if viewModel.bookings.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No Bookings Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("When customers book your services, they will appear here.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredBookings) { booking in
                                BookingCard(
                                    booking: booking,
                                    updateBookingStatus: viewModel.updateBookingStatus
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Your Bookings")
            .navigationBarItems(trailing:
                Picker("Filter", selection: $viewModel.statusFilter) {
                    Text("All").tag(nil as BookingStatus?)
                    Text("Pending").tag(BookingStatus.pending as BookingStatus?)
                    Text("Confirmed").tag(BookingStatus.confirmed as BookingStatus?)
                    Text("In Progress").tag(BookingStatus.inProgress as BookingStatus?)
                    Text("Completed").tag(BookingStatus.completed as BookingStatus?)
                    Text("Cancelled").tag(BookingStatus.cancelled as BookingStatus?)
                }
                .pickerStyle(MenuPickerStyle())
            )
            .onAppear {
                viewModel.loadBookings()
            }
        }
    }
}
