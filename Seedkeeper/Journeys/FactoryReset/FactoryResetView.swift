//
//  FactoryResetView.swift
//  Seedkeeper
//
//  Created by Satochip on 23/09/2024.
//

import Foundation
import CoreGraphics
import QRCode
import SwiftUI
import SatochipSwift

enum ResetMode {
    case start
    case sendResetCommand
}

enum ResetResult {
    case success
    case aborted
    case cancelled
    case notSetup
    case unknown
    case unsupported
}

struct FactoryResetView: View {
    
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    
    @State var hasUserConfirmedTerms = false
    
    func getActionButtonTitle() -> String {
        switch cardState.resetMode {
        case .start:
            return String(localized: "start")
        case .sendResetCommand:
            return String(localized: "factoryResesetSendCommand")
        } 
    }
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Spacer()
                    .frame(height: 60)
                
                SatoText(text: "factoryReset", style: .SKStrongBodyDark)
                
//                Spacer()
//                    .frame(height: 16)
//                
//                SatoText(text: "factoryResetSubtitle", style: .SKStrongBodyDark)
                
                Spacer()
                    
                
                SatoText(text: "factoryResetWarningText", style: .danger)
                
                Spacer()
                    .frame(height: 16)
                
                if cardState.resetMode == .start {
                    //checkbox with confirmation
                    SatoToggleWarning(isOn: $hasUserConfirmedTerms, label: "factoryResetConfirmationText")
                } else if cardState.resetMode == .sendResetCommand &&
                            cardState.resetRemainingSteps != 0x00 &&
                            cardState.resetRemainingSteps != 0xFF {
                    SatoText(text: String(localized: "stepsRemaining") + "\(cardState.resetRemainingSteps)", style: .SKStrongBodyDark)
                }
                Spacer()
                
                SKButton(text: getActionButtonTitle(), 
                         style: .regular,
                         horizontalPadding: 66,
                         isEnabled: $hasUserConfirmedTerms.wrappedValue,
                         action: 
                            {
                                switch cardState.resetMode {
                                case .start:
                                    cardState.resetMode = .sendResetCommand //.tapCard
                                case .sendResetCommand:
                                    cardState.requestFactoryReset()
                                }
                            }
                )
                
                Spacer().frame(height: 16)
                
                SKButton(text: "cancel", style: .regular, horizontalPadding: 66, action: {
                        homeNavigationPath.removeLast()
                    }
                )
                
                Spacer().frame(height: 16)

            }
            .padding([.leading, .trailing], Dimensions.lateralPadding)
        }
        .onDisappear {
            cardState.resetMode = .start
            cardState.resetRemainingSteps = 0xFF
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
                SatoText(text: "factoryResetTitle", style: .lightTitleDark)
            }
        }
    }
}

