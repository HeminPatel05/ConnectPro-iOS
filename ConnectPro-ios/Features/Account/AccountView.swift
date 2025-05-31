import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccountView: View {
    @StateObject private var userDataManager = UserDataManager()
    @State private var showLogoutAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    // Derived state
    @State private var firstName: String = ""
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(greeting), \(userDataManager.fullName.components(separatedBy: " ").first ?? "User")")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.top)
                            
                            Text("Manage your account settings")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Profile Image with AsyncImage
                        NavigationLink(destination: EditProfileView().environmentObject(userDataManager)) {
                            if let url = URL(string: userDataManager.profileImageURL), !userDataManager.profileImageURL.isEmpty {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.blue, lineWidth: 2)
                                )
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.gray)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.blue, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding()
                    
                    // Main Content Sections
                    VStack(spacing: 8) {
                        // Account Settings
                        VStack {
                            NavigationLink(destination: EditProfileView().environmentObject(userDataManager)) {
                                SettingRow(icon: "person.fill", title: "Edit Account Info", iconColor: .blue)
                            }
                            
                            // Only show Manage Address for non-Provider users
                            if userDataManager.userType != "Provider" {
                                Divider()
                                NavigationLink(destination: ManageAddressView()) {
                                    SettingRow(icon: "house.fill", title: "Manage Address", iconColor: .green)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        
                        // App Info
                        VStack {
                            NavigationLink(destination: AboutAppView()) {
                                SettingRow(icon: "info.circle.fill", title: "About the App", iconColor: .purple)
                            }
                            Divider()
                            NavigationLink(destination: SupportView()) {
                                SettingRow(icon: "questionmark.circle.fill", title: "Help & Support", iconColor: .orange)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        
                        // Logout Button with consistent style
                        VStack {
                            Button(action: { showLogoutAlert = true }) {
                                SettingRow(icon: "arrow.right.square.fill", title: "Log Out", iconColor: .red)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .actionSheet(isPresented: $showLogoutAlert) {
                            ActionSheet(
                                title: Text("Log Out"),
                                message: Text("Are you sure you want to log out?"),
                                buttons: [
                                    .destructive(Text("Log Out"), action: handleLogout),
                                    .cancel()
                                ]
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Version Info
                    Text("App v1.0.2")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: EditProfileNavigationLink().environmentObject(userDataManager))
        }
        .onAppear {
            userDataManager.updateData()
        }
    }
    
    // MARK: - Helper Methods
    private func handleLogout() {
        do {
            try Auth.auth().signOut()
            transitionToLoginScreen()
        } catch {
            print("Logout error: \(error.localizedDescription)")
        }
    }
    
    private func transitionToLoginScreen() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let loginVC = storyboard.instantiateInitialViewController() {
            UIView.transition(with: window,
                            duration: 0.3,
                            options: .transitionCrossDissolve,
                            animations: { window.rootViewController = loginVC },
                            completion: nil)
        }
    }
}


fileprivate struct EditProfileNavigationLink: View {
    @EnvironmentObject var userDataManager: UserDataManager
    
    var body: some View {
        NavigationLink(destination: EditProfileView().environmentObject(userDataManager)) {
            Text("Edit")
                .foregroundColor(.blue)
        }
    }
}

//struct SettingRow: View {
//    var icon: String
//    var title: String
//    var iconColor: Color
//    
//    var body: some View {
//        HStack(spacing: 15) {
//            Image(systemName: icon)
//                .font(.system(size: 20))
//                .foregroundColor(iconColor)
//                .frame(width: 30, height: 30)
//            
//            Text(title)
//                .font(.body)
//            
//            Spacer()
//            
//            Image(systemName: "chevron.right")
//                .font(.system(size: 14))
//                .foregroundColor(.gray)
//        }
//        .padding(.vertical, 8)
//    }
//}
