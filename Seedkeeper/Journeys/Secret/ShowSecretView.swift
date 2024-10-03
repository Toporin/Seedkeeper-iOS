//
//  ShowSecretView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 04/05/2024.
//

import Foundation
import CoreGraphics
import QRCode
import SwiftUI
import SatochipSwift

struct ShowSecretView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    var secret: SeedkeeperSecretHeader
    @State var isSecretHeaderFetched: Bool = false
    
    // delete secret
    @State private var showConfirmMsg: Bool = false
    @State var hasUserConfirmedTerms = false
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack {
                    
                    Spacer()
                        .frame(height: 60)
                    
                    SatoText(text: "manageYourSecret", style: .SKStrongBodyDark)
                    
                    Spacer()
                        .frame(height: 16)
                    
                    SatoText(text: "secretInfoSubtitle", style: .SKStrongBodyDark)
                    
                    Spacer()
                        .frame(height: 16)
                    
                    SKLabel(title: "label", content: secret.label)
                    
                    // MARK: Fields specific per secret type
                    if secret.type == .password {
                        if let payload = cardState.currentSecretPayload as? PasswordPayload {
                            if let login = payload.login {
                                SKLabel(title: "Login", content: login)
                            }
                            if let url = payload.url {
                                SKLabel(title: "Url", content: url)
                            }
                        }

                    } else if secret.type == .masterseed && secret.subtype == 0x01 {
                        
                        if let payload = cardState.currentSecretPayload as? MnemonicPayload {
                            if let mnemonicSize = payload.getMnemonicSize(){
                                SKLabel(title: "mnemonicSize", content: mnemonicSize.humanReadableName())
                            }
                            if let passphrase = payload.passphrase {
                                SKLabel(title: "passphrase", content: passphrase)
                            }
                            if let descriptor = payload.descriptor {
                                // we use a SKSecretViewer for descriptor
                                HStack {
                                    SatoText(text: "descriptor", style: .SKStrongBodyDark)
                                    Spacer()
                                }
                                SKSecretViewer(secretType: .walletDescriptor,
                                               contentText:  .constant(descriptor)
                                )
                            }
                            
                        }
                        
                    } else if secret.type == .bip39Mnemonic {
                        if let payload = cardState.currentSecretPayload as? Bip39MnemonicPayload {
                            if let mnemonicSize = payload.getMnemonicSize(){
                                SKLabel(title: "mnemonicSize", content: mnemonicSize.humanReadableName())
                            }
                            if let passphrase = payload.passphrase {
                                SKLabel(title: "passphrase", content: passphrase)
                            }
                        }
                        
                    } else if secret.type == .electrumMnemonic {
                        if let payload = cardState.currentSecretPayload as? ElectrumMnemonicPayload {
                            if let mnemonicSize = payload.getMnemonicSize(){
                                SKLabel(title: "mnemonicSize", content: mnemonicSize.humanReadableName())
                            }
                            if let passphrase = payload.passphrase {
                                SKLabel(title: "passphrase", content: passphrase)
                            }
                        }
                        
                    } else if secret.type == .pubkey {
                        if let payload = cardState.currentSecretPayload as? PubkeyPayload {
                            SKLabel(title: "fingerprint", content: SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: payload.getPayloadBytes()).bytesToHex)
                        }
                    }
                    
                    // MARK: secret field
                    HStack {
                        SatoText(text: cardState.currentSecretPayload?.humanReadableName() ?? "Secret", style: .SKStrongBodyDark)
                        Spacer()
                    }
                    
                    Spacer()
                        .frame(height: 16)
                    
                    if let payload = cardState.currentSecretPayload {
                        SKSecretViewer(secretType: secret.type,
                                       contentText:  .constant(payload.getContentString())
                        )
                    }else {
                        // empty secret field
                        SKSecretViewer(secretType: .password, // TODO: use something else?
                                       contentText: .constant(String(localized: "helpMsgToExportSecret")))
                        
                    }
                    
                    Spacer()
                        .frame(height: 30)
                    
                    // Mark: confirm delete msg
                    if showConfirmMsg {
                        //checkbox with confirmation
                        SatoText(text: "secretResetWarningText", style: .danger)
                        SatoToggleWarning(isOn: $hasUserConfirmedTerms, label: "factoryResetConfirmationText")
                    }
                    
                    // MARK: action buttons
                    HStack {
                        
                        if let version = cardState.masterCardStatus?.protocolVersion, version >= 0x0002 {
                            // Only show delete button if supported by card
                            SKActionButtonSmall(title: String(localized: "delete"), icon: "ic_trash", isEnabled: .constant(true)) {
                                if showConfirmMsg == false {
                                    showConfirmMsg = true
                                } else if hasUserConfirmedTerms {
                                    cardState.currentSecretHeader = secret
                                    cardState.requestDeleteSecret()
                                }
                            }
                        }
                        
                        Spacer()
                        
                        SKActionButtonSmall(title: String(localized: "export"), icon: "ic_eye", isEnabled: .constant(true)) {
                            cardState.requestExportSecret(with: secret)
                            isSecretHeaderFetched = true
                        }
                    }
                    .padding([.leading, .trailing], 0)
                    
                    Spacer()
                        .frame(height: 30)
                    
                }
                .padding([.leading, .trailing], Dimensions.lateralPadding)
            }
        }
        .onDisappear {
            cardState.cleanShowSecret()
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
                SatoText(text: "mySecretViewTitle", style: .lightTitleDark)
            }
        }
    }
}
