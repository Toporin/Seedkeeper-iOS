//
//  Log.swift
//  Seedkeeper
//
//  Created by Satochip on 27/09/2024.
//

import Foundation

enum LogLevel: String, Codable {
    case info
    case debug
    case warn
    case error
    case critical
}

public struct Log: Codable, Hashable {
    var uid = UUID()
    var time: Date
    var level: LogLevel
    var msg: String
    var tag: String
    
    func toString() -> String {
        let txt = "[\(time)] \(level.rawValue): \(tag) \(msg) \n"
        return txt
    }
}
