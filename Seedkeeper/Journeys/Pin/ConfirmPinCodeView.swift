//
//  ConfirmPinCodeView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import Foundation
import SwiftUI

struct ConfirmPinCodeView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    
    @Binding var homeNavigationPath: NavigationPath
    @State private var pinCodeConfirmation: String = ""
    @State private var shouldShowPinCodeError: Bool = false
    var pinCodeNavigationData: PinCodeNavigationData
    
    var isContinueBtnEnabled: Bool {
        return !pinCodeConfirmation.isEmpty
    }
        
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                
                SatoText(text: "confirmPinCode", style: .title)
                
                Spacer().frame(height: 10)
                
                SatoText(text: "confirmPinCodeSubtitle", style: .SKMenuItemTitle)
                
                Spacer().frame(height: 24)
                
                SecureTextInput(placeholder: String(localized: "placeholder.confirmPinCode"), text: $pinCodeConfirmation)
                
                if shouldShowPinCodeError {
                    Text(String(localized: "pinCodeDoesNotMatch"))
                        .font(.custom("Roboto-Regular", size: 12))
                        .foregroundColor(Colors.ledRed)
                }
                
                Spacer()
                
                SKButton(text: String(localized: "confirm"), style: .regular, horizontalPadding: 66, isEnabled: isContinueBtnEnabled, action: {
                    guard let pinCodeToValidate = self.pinCodeNavigationData.pinCode, Validator.isPinValid(pin: pinCodeConfirmation) && pinCodeConfirmation == pinCodeToValidate else {
                        shouldShowPinCodeError = true
                        return
                    }
                    
                    if pinCodeConfirmation == pinCodeToValidate {
                        print("Pin codes matches: \(pinCodeConfirmation) == \(pinCodeToValidate)")
                        cardState.pinCodeToSetup = pinCodeConfirmation
                        if pinCodeNavigationData.mode == .confirmPinCode {
                            cardState.requestInitPinOnCard()
                        } else if pinCodeNavigationData.mode == .updatePinCodeConfirmNew {
                            cardState.requestUpdatePinOnCard(newPin: pinCodeToValidate)
                        } else if pinCodeNavigationData.mode == .confirmPinCodeForBackupCard {
                            cardState.requestInitPinOnBackupCard()
                        }
                        
                    } else {
                        print("Pin code does not match")
                    }
                })
                
                Spacer().frame(height: 16)
            }
            .onChange(of: pinCodeConfirmation) { _ in
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
