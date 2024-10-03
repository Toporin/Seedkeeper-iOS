//
//  SatoToggleWarning.swift
//  Seedkeeper
//
//  Created by Satochip on 03/10/2024.
//

import SwiftUI

struct SatoToggleWarning: View {
    @Binding var isOn: Bool
    var label: String
    
    var body: some View {
        HStack {
            Spacer()
            
            ZStack {
                Circle()
                    .strokeBorder(Color.red, lineWidth: 2)
                    .background(isOn ? Color.red : .clear)
                    .clipShape(Circle())
                    .frame(width: 28, height: 28)
            }
            .onTapGesture {
                self.isOn.toggle()
            }
            
            Spacer()
                .frame(width: 18)
            
            SatoText(text: label, style: .danger)
                .frame(height: 38)
                .lineLimit(nil)
            
            Spacer()
        }
        .padding()
    }
}
