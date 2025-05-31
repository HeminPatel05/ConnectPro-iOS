//
//  FAQView.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/17/25.
//

import SwiftUI


struct FAQView: View {
    var body: some View {
        List {
            FAQItem(question: "How do I update my profile?", answer: "Go to the Account tab and tap on Edit Profile to update your information.")
            FAQItem(question: "Can I use multiple addresses?", answer: "Yes! You can add and manage multiple addresses in Account > Manage Address.")
            FAQItem(question: "How do I delete my account?", answer: "Please contact our support team to process account deletion requests.")
        }
        .navigationTitle("FAQs")
    }
}

struct FAQItem: View {
    var question: String
    var answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
        }
        .padding(.vertical, 5)
    }
}



