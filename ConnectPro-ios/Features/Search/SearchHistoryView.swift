//
//  SearchHistoryView.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/22/25.
//


import SwiftUI
import Firebase

struct SearchHistoryView: View {
    @ObservedObject var viewModel: SearchViewModel
    @State private var showClearConfirmation = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Search header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for a service", text: $viewModel.searchText, onCommit: {
                        viewModel.search()
                    })
                    .onSubmit {
                        // Navigate to search results when user presses enter/return
                        if !viewModel.searchText.isEmpty {
                            // This would be handled by your navigation system
                        }
                    }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    } else {
                        Button(action: {
                            // Voice search action
                        }) {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 5)
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Recent searches section
                    if !viewModel.recentSearches.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Recent Searches")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    showClearConfirmation = true
                                }) {
                                    Text("Clear")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                .alert(isPresented: $showClearConfirmation) {
                                    Alert(
                                        title: Text("Clear Recent Searches"),
                                        message: Text("Are you sure you want to clear all recent searches?"),
                                        primaryButton: .destructive(Text("Clear")) {
                                            viewModel.clearRecentSearches()
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                            
                            ForEach(viewModel.recentSearches, id: \.self) { search in
                                Button(action: {
                                    viewModel.searchText = search
                                    viewModel.search()
                                    // Navigate to search results
                                }) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.gray)
                                        
                                        Text(search)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.left")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                    
                    // Popular searches section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Popular Searches")
                            .font(.headline)
                        
                        ForEach(viewModel.popularSearches, id: \.self) { search in
                            Button(action: {
                                viewModel.searchText = search
                                viewModel.search()
                                // Navigate to search results
                            }) {
                                HStack {
                                    Image(systemName: serviceSFSymbol(for: search))
                                        .foregroundColor(.blue)
                                    
                                    Text(search)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                .padding(.top, 10)
            }
        }
        .navigationBarHidden(true)
        .background(Color(.systemGray6).ignoresSafeArea())
    }
    
    // Helper for service icons
    private func serviceSFSymbol(for service: String) -> String {
        switch service.lowercased() {
        case _ where service.lowercased().contains("haircut"):
            return "scissors"
        case _ where service.lowercased().contains("gym"):
            return "dumbbell.fill"
        case _ where service.lowercased().contains("yoga"):
            return "figure.yoga"
        case _ where service.lowercased().contains("car"):
            return "car.fill"
        case _ where service.lowercased().contains("plumber"):
            return "wrench.fill"
        case _ where service.lowercased().contains("clean"):
            return "house.fill"
        case _ where service.lowercased().contains("repair"):
            return "wrench.and.screwdriver.fill"
        case _ where service.lowercased().contains("spa"):
            return "sparkles"
        case _ where service.lowercased().contains("massage"):
            return "hand.wave.fill"
        default:
            return "star.fill"
        }
    }
}