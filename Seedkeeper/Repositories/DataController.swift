//
//  DataController.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 02/05/2024.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    
    // MARK: - Singleton Instance
    static let shared = DataController()
    
    let container: NSPersistentContainer
    
    // MARK: - Private Initializer
    private init() {
        container = NSPersistentContainer(name: "Seedkeeper")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Core Data Saving support
    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("An error occurred while saving: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Core Data Deleting support
    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
        save()
    }
    
    func deleteAll(_ objects: [NSManagedObject]) {
        objects.forEach { container.viewContext.delete($0) }
        save()
    }
}

// MARK: - Logs

extension NSManagedObjectContext {
    func saveLogEntry(log: Log) {
        let logEntry = LogEntry(context: self)
        logEntry.date = log.time
        logEntry.type = log.level.rawValue
        logEntry.message = log.msg
        try? save()
    }
}

// MARK: - Previously used logins

extension NSManagedObjectContext {
    func saveLoginEntry(loginModel: UsedLoginModel) {
        // Fetch all existing login entries first to check for duplicates
        let allLogins = fetchAllLoginEntries()
        
        let isDuplicate = allLogins.contains { $0.login == loginModel.login }
        
        if isDuplicate {
            print("Duplicate login found: \(loginModel.login). Save operation cancelled.")
            return
        }
        
        // No duplicate found, proceed with saving the new entry
        let loginEntry = UsedLogin(context: self)
        loginEntry.login = loginModel.login
        try? save()
    }
    
    func fetchAllLoginEntries() -> [UsedLogin] {
        let request: NSFetchRequest<UsedLogin> = UsedLogin.fetchRequest()
        return (try? fetch(request)) ?? []
    }
    
    func deleteLoginEntry(loginModel: UsedLoginModel) {
        let login = UsedLogin(context: self)
        login.login = loginModel.login
        delete(login)
        try? save()
    }
}

