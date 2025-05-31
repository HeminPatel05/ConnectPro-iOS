//
//  SupportView.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/17/25.
//

import SwiftUI


struct SupportView: View {
    var body: some View {
        List {
            Section(header: Text("HELP CENTER")) {
                NavigationLink(destination: FAQView()) {
                    SettingRow(icon: "questionmark.circle", title: "Frequently Asked Questions", iconColor: .blue)
                }
                
                Button(action: {
                    // Open email client
                    if let url = URL(string: "mailto:support@connectpro.com") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    SettingRow(icon: "envelope", title: "Email Support", iconColor: .green)
                }
                
                Button(action: {
                    // Call support
                    if let url = URL(string: "tel:18005551234") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    SettingRow(icon: "phone", title: "Call Support", iconColor: .orange)
                }
            }
        }
        .navigationTitle("Help & Support")
    }
}



struct SettingRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}


