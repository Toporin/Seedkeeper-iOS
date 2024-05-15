//
//  LogModel.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 02/05/2024.
//

import Foundation
import CoreData

enum LogType: String {
    case info
    case warning
    case error
}

struct LogModel {
    var id: UUID
    var date: Date
    var type: LogType
    var message: String
    
    init(id: UUID = UUID(), date: Date = Date(), type: LogType, message: String) {
        self.id = id
        self.date = date
        self.type = type
        self.message = message
    }
    
    init(logEntry: LogEntry) {
        self.id = logEntry.id ?? UUID()
        self.date = logEntry.date ?? Date()
        self.type = LogType(rawValue: logEntry.type!)!
        self.message = logEntry.message!
    }
}
