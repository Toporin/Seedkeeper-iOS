//
//  SKImageButton.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 22/08/2024.
//

import Foundation
import SwiftUI

struct SKImageButton: View {
    var iconName: String
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
            HStack {
                Image(iconName)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
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
