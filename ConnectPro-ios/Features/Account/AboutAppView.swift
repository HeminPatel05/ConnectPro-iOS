//
//  AboutAppView.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/17/25.
//
import SwiftUI

struct AboutAppView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top)
                
                Text("ConnectPro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("About")
                        .font(.headline)
                    
                    Text("Our service booking application is designed to seamlessly connect customers with trusted local service providers for tasks like house cleaning, plumbing, lawn care, and more.")
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Version")
                        .font(.headline)
                    
                    Text("v1.0.2 (Build 104)")
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Legal")
                        .font(.headline)
                    
                    Link("Privacy Policy", destination: URL(string: "https://www.example.com/privacy")!)
                        .font(.body)
                        .foregroundColor(.blue)
                    
                    Link("Terms of Service", destination: URL(string: "https://www.example.com/terms")!)
                        .font(.body)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("About the App")
    }
}





