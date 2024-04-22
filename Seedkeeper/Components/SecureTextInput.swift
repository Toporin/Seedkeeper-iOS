//
//  SecureTextInput.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import SwiftUI

struct SecureTextInput: View {
    // MARK: - Properties
    let placeholder: String
    @State private var showText: Bool = false
    @Binding var text: String
    var onCommit: (()->Void)?
    
    var body: some View {
        
        HStack {
            ZStack {
                SecureField(placeholder, text: $text, onCommit: {
                    onCommit?()
                })
                .opacity(showText ? 0 : 1)
                
                
                if showText {
                    HStack {
                        Text(text)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
            }
            
            Button(action: {
                showText.toggle()
            }, label: {
                Image(systemName: showText ? "eye.slash" : "eye")
            })
            .accentColor(.black)
        }
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black, lineWidth: 1)
                    .foregroundColor(.clear))
    }
    
}
