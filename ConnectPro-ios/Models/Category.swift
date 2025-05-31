//
//  Category.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/22/25.
//


import SwiftUI
import Firebase
import FirebaseFirestore

struct Category: Identifiable {
    let id: String
    let name: String
    let iconName: String?
    
    // Initialize from Firestore document
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let name = data["name"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.name = name
        self.iconName = data["iconName"] as? String
    }
    
    init(id: String, name: String, iconName: String? = nil) {
        self.id = id
        self.name = name
        self.iconName = iconName
    }
}
