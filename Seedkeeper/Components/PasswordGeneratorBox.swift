//
//  PasswordGeneratorBox.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 25/05/2024.
//

import Foundation
import SwiftUI

class PasswordOptions: ObservableObject {
    @Published var passwordLength: Double = 8
    @Published var includeLowercase: Bool = true
    @Published var includeUppercase: Bool = false
    @Published var includeNumbers: Bool = false
    @Published var includeSymbols: Bool = false
    
    func userSelectedAtLeastOneIncludeOption() -> Bool {
        return includeLowercase || includeUppercase || includeNumbers || includeSymbols
    }
}

struct PasswordGeneratorBox: View {
    @ObservedObject var options: PasswordOptions

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Password lenght")
                .foregroundColor(.white)
            
            Slider(value: $options.passwordLength, in: 8...16, step: 1)
                .accentColor(.gray)
            
            SatoText(text: String(format: "%.0f", options.passwordLength), style: .lightSubtitle)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(0)
            
            HStack() {
                VStack {
                    HStack {
                        Spacer()
                        Toggle("", isOn: $options.includeLowercase)
                        Spacer()
                    }
                    
                    SatoText(text: "abc", style: .lightSubtitle)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Toggle("", isOn: $options.includeUppercase)
                        Spacer()
                    }
                    
                    SatoText(text: "ABC", style: .lightSubtitle)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Toggle("", isOn: $options.includeNumbers)
                        Spacer()
                    }
                    
                    SatoText(text: "123", style: .lightSubtitle)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Toggle("", isOn: $options.includeSymbols)
                        Spacer()
                    }
                    
                    SatoText(text: "$#!", style: .lightSubtitle)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .white))
            .foregroundColor(.white)
        }
        .padding(20)
        .background(Colors.purpleBtn.opacity(0.5))
        .cornerRadius(20)
    }
}
