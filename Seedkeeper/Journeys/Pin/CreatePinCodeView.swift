//
//  CreatePinCodeView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import Foundation
import SwiftUI

enum PinCodeNavigationPath: Hashable {
    case createPinCode
    case confirmPinCode
    case updatePinCode
}

struct PinCodeNavigationData: Hashable {
    let mode: PinCodeNavigationPath
    let pinCode: String?
}

struct CreatePinCodeView: View {
    // MARK: - Properties
    @Binding var homeNavigationPath: NavigationPath
    @State private var pinCode: String = ""
    @State private var shouldShowPinCodeError: Bool = false
    var pinCodeNavigationData: PinCodeNavigationData
        
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                
                SatoText(text: pinCodeNavigationData.mode == .createPinCode ? "createPinCode" : "editPinCode", style: .title)
                
                Spacer().frame(height: 10)
                
                SatoText(text: pinCodeNavigationData.mode == .createPinCode ? "createPinCodeSubtitle" : "editPinCodeSubtitle", style: .SKMenuItemTitle)
                
                Spacer().frame(height: 24)
                
                SecureTextInput(placeholder: String(localized: pinCodeNavigationData.mode == .createPinCode ?  "placeholder.enterPinCode" : "placeholder.currentPinCode"), text: $pinCode)
                
                if shouldShowPinCodeError {
                    Text(String(localized: "invalidPinCode"))
                        .font(.custom("Roboto-Regular", size: 12))
                        .foregroundColor(Colors.ledRed)
                }
                
                Spacer()
                
                SKButton(text: String(localized: "next"), style: .regular, horizontalPadding: 66, action: {
                    print("pinCode: \(pinCode)")
                    guard Validator.isPinValid(pin: pinCode) else {
                        shouldShowPinCodeError = true
                        return
                    }
                    homeNavigationPath.append(NavigationRoutes.confirmPinCode(PinCodeNavigationData(mode: .confirmPinCode, pinCode: pinCode)))
                })
                
                Spacer().frame(height: 16)
            }
            .onChange(of: pinCode) { _ in
                shouldShowPinCodeError = false
            }
            .padding([.leading, .trailing], 32)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            homeNavigationPath.removeLast()
        }) {
            Image("ic_back_dark")
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                SatoText(text: "setup", style: .lightTitleDark)
            }
        }
    }
}
