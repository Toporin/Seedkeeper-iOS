//
//  Validator.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import Foundation

struct Validator {
    // Pin validation
    static func isPinValid(pin: String) -> Bool {
        return pin.count >= 4 && pin.count <= 16
    }
}
