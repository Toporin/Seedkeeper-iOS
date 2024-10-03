//
//  PasswordGeneratorBox.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 25/05/2024.
//

import Foundation
import SwiftUI

class PasswordOptions: ObservableObject, Equatable {
    @Published var passwordLength: Double = 12
    @Published var minPasswordLength: Double = 8
    @Published var includeLowercase: Bool = true
    @Published var includeUppercase: Bool = true
    @Published var includeNumbers: Bool = true
    @Published var includeSymbols: Bool = true
    @Published var isMemorablePassword: Bool = false {
        didSet {
            passwordLength = isMemorablePassword ? 6 : 12
            minPasswordLength = isMemorablePassword ? 4 : 8
            includeNumbers = isMemorablePassword ? false : true
            includeSymbols = isMemorablePassword ? false : true
        }
    }
    
    func userSelectedAtLeastOneIncludeOption() -> Bool {
        return includeLowercase || includeUppercase || includeNumbers || includeSymbols || isMemorablePassword
    }
    
    static func == (lhs: PasswordOptions, rhs: PasswordOptions) -> Bool {
        return lhs.passwordLength == rhs.passwordLength &&
            lhs.includeLowercase == rhs.includeLowercase &&
            lhs.includeUppercase == rhs.includeUppercase &&
            lhs.includeNumbers == rhs.includeNumbers &&
            lhs.includeSymbols == rhs.includeSymbols &&
            lhs.isMemorablePassword == rhs.isMemorablePassword
    }
}

struct PasswordGeneratorBox: View {
    @ObservedObject var options: PasswordOptions

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "passwordLength"))
                .foregroundColor(.white)
            
            Slider(value: $options.passwordLength, in: options.minPasswordLength...16, step: 1)
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
            
            Spacer()
                .frame(height: 6)
            
            HStack {
                SatoToggle(isOn: $options.isMemorablePassword, label: "memorablePassword")
                    .padding(0)
            }
            .padding(0)
        }
        .padding(20)
        .background(Colors.purpleBtn.opacity(0.5))
        .cornerRadius(20)
    }
}

struct SatoToggle: View {
    @Binding var isOn: Bool
    var label: String
    
    var body: some View {
        HStack {
            Spacer()
            
            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .background(isOn ? Colors.ledGreen : .clear)
                    .clipShape(Circle())
                    .frame(width: 28, height: 28)
            }
            .onTapGesture {
                self.isOn.toggle()
            }
            
            Spacer()
                .frame(width: 18)
            
            SatoText(text: label, style: .lightSubtitle)
                .frame(height: 38)
                .lineLimit(nil)
            
            Spacer()
        }
        .padding()
    }
}
