//
//  SKActionButtonSmall.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 21/06/2024.
//

import Foundation
import SwiftUI

struct SKActionButtonSmall: View {
    let title: String
    let icon: String
    @Binding var isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                    .font(.custom("OpenSans-SemiBold", size: 18))
                    .lineLimit(1)
                    .padding(.leading, 10)
                
                Spacer()
                    .frame(width: 4)
                
                Image(icon)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
                    .padding(.trailing, 10)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40)
            .background(Colors.purpleBtn)
            .opacity(isEnabled ? 1.0 : 0.5)
            .cornerRadius(20)
        }
    }
}
