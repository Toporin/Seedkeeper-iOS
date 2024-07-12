//
//  SKButton.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import Foundation
import SwiftUI

enum ButtonStyle {
    case confirm
    case inform
    case danger
    case regular
    case satoGreen

    var backgroundColor: Color {
        switch self {
        case .confirm:
            return Colors.buttonDefault
        case .inform:
            return Colors.buttonInform
        case .danger:
            return Colors.buttonDefault
        case .regular:
            return Colors.buttonRegular
        case .satoGreen:
            return Colors.satoGreen
        }
    }

    var cornerRadius: CGFloat {
        return 20
    }
}

struct SKButton: View {
    var text: String
    var style: ButtonStyle
    var horizontalPadding: CGFloat = 16
    var staticWidth: CGFloat?
    var isEnabled: Bool?
    var action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled ?? true {
                action()
            }
        }) {
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 8)
                .background(isEnabled != nil ? (isEnabled! ? style.backgroundColor : Color.gray) : style.backgroundColor)
                .cornerRadius(24)
                .opacity(isEnabled != nil ? (isEnabled! ? 1.0 : 0.5) : 1.0)
        }
        .frame(height: 40)
        .frame(maxWidth: staticWidth ?? .infinity)
        .disabled(isEnabled == nil ? false : !(isEnabled!))
    }
}
