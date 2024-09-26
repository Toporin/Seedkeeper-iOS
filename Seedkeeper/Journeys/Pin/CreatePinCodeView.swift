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
    case updatePinCodeDefineNew
    case updatePinCodeConfirmNew
    case createPinCodeForBackupCard
    case confirmPinCodeForBackupCard
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
    
    var isContinueBtnEnabled: Bool {
        return !pinCode.isEmpty
    }
    
    func getViewTitle() -> String {
        switch pinCodeNavigationData.mode {
        case .createPinCode:
            return "createPinCode"
        case .confirmPinCode:
            return "confirmPinCode"
        case .updatePinCodeDefineNew:
            return "updatePinCodeDefineNew"
        case .updatePinCodeConfirmNew:
            return "updatePinCodeConfirmNew"
        case .createPinCodeForBackupCard:
            return "createPinCodeForBackupCard"
        case .confirmPinCodeForBackupCard:
            return "confirmPinCodeForBackupCard"
        }
    }
    
    func getViewSubtitle() -> String {
        switch pinCodeNavigationData.mode {
        case .createPinCode:
            return "createPinCodeSubtitle"
        case .confirmPinCode:
            return "confirmPinCodeSubtitle"
        case .updatePinCodeDefineNew:
            return "updatePinCodeDefineNewSubtitle"
        case .updatePinCodeConfirmNew:
            return "updatePinCodeConfirmNewSubtitle"
        case .createPinCodeForBackupCard:
            return "createPinCodeForBackupCardSubtitle"
        case .confirmPinCodeForBackupCard:
            return "confirmPinCodeForBackupCardSubtitle"
        }
    }
    
    func getPlaceHolder() -> String {
        switch pinCodeNavigationData.mode {
        case .createPinCode:
            return String(localized: "placeholder.enterPinCode")
        case .confirmPinCode:
            return String(localized: "placeholder.confirmPinCode")
        case .updatePinCodeDefineNew:
            return String(localized: "placeholder.enterPinCode")
        case .updatePinCodeConfirmNew:
            return String(localized: "placeholder.confirmPinCode")
        case .createPinCodeForBackupCard:
            return String(localized: "placeholder.enterPinCode")
        case .confirmPinCodeForBackupCard:
            return String(localized: "placeholder.confirmPinCode")
        }
    }
        
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                
                SatoText(text: self.getViewTitle(), style: .title)
                
                Spacer().frame(height: 10)
                
                SatoText(text: self.getViewSubtitle(), style: .SKMenuItemTitle)
                
                Spacer().frame(height: 24)
                
                SecureTextInput(placeholder: self.getPlaceHolder(), text: $pinCode)
                
                if shouldShowPinCodeError {
                    Text(String(localized: "invalidPinCode"))
                        .font(.custom("Roboto-Regular", size: 12))
                        .foregroundColor(Colors.ledRed)
                }
                
                Spacer()
                
                SKButton(text: String(localized: "next"), style: .regular, horizontalPadding: 66, isEnabled: isContinueBtnEnabled, action: {
                    //print("pinCode: \(pinCode)") // TODO: remove
                    guard Validator.isPinValid(pin: pinCode) else {
                        shouldShowPinCodeError = true
                        return
                    }
                    if pinCodeNavigationData.mode == .createPinCode {
                        homeNavigationPath.append(NavigationRoutes.confirmPinCode(PinCodeNavigationData(mode: .confirmPinCode, pinCode: pinCode)))
                    } else if pinCodeNavigationData.mode == .createPinCodeForBackupCard {
                        homeNavigationPath.append(NavigationRoutes.confirmPinCode(PinCodeNavigationData(mode: .confirmPinCodeForBackupCard, pinCode: pinCode)))
                    }
                    // Update pin code
                    else if pinCodeNavigationData.mode == .updatePinCodeDefineNew {
                        homeNavigationPath.append(NavigationRoutes.confirmPinCode(PinCodeNavigationData(mode: .updatePinCodeConfirmNew, pinCode: pinCode)))
                    }
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
