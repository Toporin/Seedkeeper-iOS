//
//  Formatter.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 02/05/2024.
//

import Foundation

private struct FormatterConstants {
    static let dateTimeFormat = "dd/MM/yyyy HH:mm:ss"
}

public class Formatter {
    func dateTimeToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = FormatterConstants.dateTimeFormat
        return formatter.string(from: date)
    }
}
