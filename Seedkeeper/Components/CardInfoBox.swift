//
//  CardInfoBox.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 02/05/2024.
//

import SwiftUI

struct CardInfoBox: View {
    let text: String
    let backgroundColor: Color
    var width: CGFloat?
    var action: (() -> Void)?
    
    var body: some View {
        SatoText(text: text, style: .SKStrongBodyLight)
            .padding()
            .frame(width: width, height: 55)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .background(backgroundColor)
            .cornerRadius(20)
            .lineLimit(1)
            .foregroundColor(.white)
            .onTapGesture {
                action?()
            }
    }
}

struct CardInfoBoxWithIcon: View {
    let text: String
    let backgroundColor: Color
    let iconName: String
    var width: CGFloat?
    var action: (() -> Void)?
    
    var body: some View {
        HStack {
            
            Spacer()
            
            SatoText(text: text, style: .SKStrongBodyLight)
            
            Spacer()
            
            Image(systemName: iconName)
        }
        .padding()
        .frame(width: width, height: 55)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .background(backgroundColor)
        .cornerRadius(20)
        .lineLimit(1)
        .foregroundColor(.white)
        .onTapGesture {
            action?()
        }
        
        
    }
}
