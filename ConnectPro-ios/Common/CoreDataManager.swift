//
//  CoreDataManager.swift
//  ConnectPro
//
//  Created by Hemin Patel on 4/26/25.
//


// MARK: - CoreData Model Extension
// Add this to your project to interact with CoreData CategoryEntity

import CoreData
import UIKit
import Firebase

// MARK: - CategoryEntity Extension
extension CategoryEntity {
    // Convert CoreData CategoryEntity to Category model
    func toCategory() -> Category {
        return Category(
            id: self.id ?? "",
            name: self.name ?? "",
            iconName: self.iconName
        )
    }
}

// MARK: - Core Data Manager
class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ConnectPro") // Replace with your actual model name
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Save context if there are changes
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                print("Unresolved CoreData save error: \(error), \(error.userInfo)")
            }
        }
    }
    
    // Add a new category
    func addCategory(id: String, name: String, iconName: String?) {
        let context = viewContext
        let entity = CategoryEntity(context: context)
        entity.id = id
        entity.name = name
        entity.iconName = iconName
        saveContext()
    }
    
    // Fetch all categories
    func fetchCategories() -> [CategoryEntity] {
        let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch categories: \(error)")
            return []
        }
    }
    
    // Delete all categories
    func deleteAllCategories() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CategoryEntity.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(batchDeleteRequest)
            saveContext()
        } catch {
            print("Failed to delete all categories: \(error)")
        }
    }
    
    // Sync categories from Firebase to CoreData
    func syncCategoriesFromFirebase(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        
        db.collection("categories").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching categories from Firebase: \(error.localizedDescription)")
                completion()
                return
            }
            
            guard let snapshot = snapshot else {
                completion()
                return
            }
            
            // Clear existing categories before syncing
            self.deleteAllCategories()
            
            // Add new categories from Firebase
            for document in snapshot.documents {
                if let data = document.data() as? [String: Any],
                   let name = data["name"] as? String {
                    let id = document.documentID
                    let iconName = data["iconName"] as? String
                    
                    self.addCategory(id: id, name: name, iconName: iconName)
                }
            }
            
            self.saveContext()
            completion()
        }
    }
}

// MARK: - Updated HomeViewModel
extension HomeViewModel {
    // Replace the Firebase fetchCategories with CoreData implementation
    func fetchCategoriesFromCoreData() {
        isLoadingCategories = true
        
        // First try to load from CoreData
        let categoryEntities = CoreDataManager.shared.fetchCategories()
        
        // If we have cached categories, use them immediately
        if !categoryEntities.isEmpty {
            self.categories = categoryEntities.map { $0.toCategory() }
            isLoadingCategories = false
            
            // Optionally refresh from Firebase in background
            refreshCategoriesFromFirebase()
        } else {
            // No cached data, need to load from Firebase first time
            refreshCategoriesFromFirebase()
        }
    }
    
    private func refreshCategoriesFromFirebase() {
        CoreDataManager.shared.syncCategoriesFromFirebase { [weak self] in
            DispatchQueue.main.async {
                // After sync, load the freshly synced data from CoreData
                let categoryEntities = CoreDataManager.shared.fetchCategories()
                self?.categories = categoryEntities.map { $0.toCategory() }
                self?.isLoadingCategories = false
            }
        }
    }
}

// MARK: - Modified Category Model
// Update your existing Category model to work with the new CoreData implementation
//struct Category: Identifiable {
//    let id: String
//    let name: String
//    var iconName: String?
//    
//    // Constructor for creating from CoreData entity
//    init(id: String, name: String, iconName: String?) {
//        self.id = id
//        self.name = name
//        self.iconName = iconName
//    }
//    
//    // Keep existing constructor for backwards compatibility
//    init?(document: QueryDocumentSnapshot) {
//        let data = document.data()
//        
//        guard let name = data["name"] as? String else {
//            return nil
//        }
//        
//        self.id = document.documentID
//        self.name = name
//        self.iconName = data["iconName"] as? String
//    }
//}
