//
//  DataController.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 02/05/2024.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "Seedkeeper")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("An error occurred while saving: \(error.localizedDescription)")
            }
        }
    }
    
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
    func saveLogEntry(log: LogModel) {
        let logEntry = LogEntry(context: self)
        logEntry.date = log.date
        logEntry.type = log.type.rawValue
        logEntry.message = log.message
        try? save()
    }
}
