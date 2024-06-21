//
//  SKLabel.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 21/06/2024.
//

import Foundation
import SwiftUI

struct SKLabel: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                SatoText(text: title, style: .SKStrongBodyDark)
                Spacer()
            }
            Text(content)
                .font(.custom("OpenSans-Regular", size: 16))
                .lineSpacing(24)
                .multilineTextAlignment(.leading)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 33, maxHeight: 33)
                .background(Colors.purpleBtn.opacity(0.5))
                .cornerRadius(20)
        }
        
    }
}
