//
//  Colors.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import Foundation
import SwiftUI

struct Colors {
    static let darkPurple: Color = Color.fromHex("#4A3B5C")
    static let lightPurple: Color = Color.fromHex("#8800FF")
    static let darkMenuButton: Color = Color.fromHex("#2D2F44")
    static let lightMenuButton: Color = Color.fromHex("#4B5976")
    static let menuSeparator: Color = Color.fromHex("#585D72")
    static let ledGreen: Color = Color.fromHex("#64FFC7")
    static let ledRed: Color = Color.fromHex("#FF2D52")
    static let buttonDefault: Color = Color.fromHex("#595D70")
    static let buttonRegular: Color = Color.fromHex("#372352")
    static let buttonInform: Color = Color.fromHex("#525684")
    static let separator: Color = Color.fromHex("#585D72")
    static let purpleBtn: Color = Color.fromHex("#3B2055")
    static let ledBlue: Color = Color.fromHex("#65BBE0")
}

import SwiftUI

extension Color {
    /// Converts a hex string to a Color object. Returns red color if conversion went wrong
    /// - Parameters:
    ///   - hex: A string in hexadecimal format, optionally prefixed with `#`. Can be 6 or 8 digits long (with alpha).
    /// - Returns: A Color object corresponding to the hex string, or nil if the format is invalid.
    static func fromHex(_ hex: String) -> Color {
        let r, g, b, a: Double
        let start = hex.hasPrefix("#") ? hex.index(hex.startIndex, offsetBy: 1) : hex.startIndex
        let hexColor = String(hex[start...])

        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        guard scanner.scanHexInt64(&hexNumber) else { return .red }
        
        if hexColor.count == 8 {
            r = Double((hexNumber & 0xff000000) >> 24) / 255
            g = Double((hexNumber & 0x00ff0000) >> 16) / 255
            b = Double((hexNumber & 0x0000ff00) >> 8) / 255
            a = Double(hexNumber & 0x000000ff) / 255
        } else if hexColor.count == 6 {
            r = Double((hexNumber & 0xff0000) >> 16) / 255
            g = Double((hexNumber & 0x00ff00) >> 8) / 255
            b = Double(hexNumber & 0x0000ff) / 255
            a = 1.0
        } else {
            return .red
        }

        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
