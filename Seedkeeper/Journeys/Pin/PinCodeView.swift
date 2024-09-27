//
//  PinCodeView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 24/05/2024.
//

import Foundation
import SwiftUI

struct PinCodeView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    @State private var pinCode: String = ""
    
    var actionAfterPin: ActionAfterPin
    var isContinueBtnEnabled: Bool {
        return !pinCode.isEmpty
    }
        
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                
                SatoText(text: "pinCode", style: .title)
                
                Spacer().frame(height: 10)
                
                SatoText(text: "pinCodeSubtitle", style: .SKMenuItemTitle)
                
                Spacer().frame(height: 24)
                
                SecureTextInput(placeholder: String(localized: "placeholder.enterPinCode"), text: $pinCode)
                
                Spacer()
                
                SKButton(text: String(localized: "confirm"), style: .regular, horizontalPadding: 66, isEnabled: isContinueBtnEnabled, action: {
                    switch actionAfterPin {
                    case .rescanCard:
                        cardState.pinForMasterCard = pinCode
                        homeNavigationPath = .init()
                        cardState.scan(for: .master)
                    case .continueBackupFlow:
                        cardState.pinForBackupCard = pinCode
                        homeNavigationPath.removeLast()
                    case .editPinCode:
                        cardState.pinForMasterCard = pinCode
                        homeNavigationPath.append(NavigationRoutes.editPinCode)
                    case .dismiss:
                        cardState.pinForMasterCard = pinCode
                        homeNavigationPath.removeLast()
                    }
                })
                
                Spacer().frame(height: 16)
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
                SatoText(text: "pinCodeViewTitle", style: .lightTitleDark)
            }
        }
    }
}
