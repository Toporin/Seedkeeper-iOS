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
    @State var shouldShowSeedQR: Bool = false
    @State var isSecretHeaderFetched: Bool = false
    
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
                    
                    SKLabel(title: "label", content: secret.label)
                    
                    // MARK: Fields specific per secret type
                    if secret.type == .password {
                        
                        if let payload = cardState.currentSecretPayload as? PasswordPayload {
                            SKLabel(title: "Login", content: payload.login ?? "(none)")
                            SKLabel(title: "Url", content: payload.url ?? "(none)")
                        } else {
                            SKLabel(title: "Login", content: "")
                            SKLabel(title: "Url", content: "")
                        }
                        
                    } else if secret.type == .masterseed && secret.subtype == 0x01 {
                        
                        if let payload = cardState.currentSecretPayload as? MnemonicPayload {
                            SKLabel(title: "mnemonicSize", content: payload.getMnemonicSize()?.humanReadableName() ?? "(none)")
                            SKLabel(title: "passphrase", content: payload.passphrase ?? "(none)")
                            //SKLabel(title: "descriptor", content: payload.descriptor ?? "(none)")
                            
                            if let descriptor = payload.descriptor {
                                // we use a SKSecretViewer for descriptor
                                HStack {
                                    SatoText(text: "descriptor", style: .SKStrongBodyDark)
                                    Spacer()
                                }
                                SKSecretViewer(secretType: .walletDescriptor,
                                               shouldShowSeedQRCode: .constant(false),
                                               contentText:  .constant(descriptor)
                                )
                            }
                            
                        } else {
                            SKLabel(title: "mnemonicSize", content: "")
                            SKLabel(title: "passphrase", content: "")
                            SKLabel(title: "descriptor", content: "")
                        }
                        
                    } else if secret.type == .bip39Mnemonic {
                        
                        if let payload = cardState.currentSecretPayload as? Bip39MnemonicPayload {
                            SKLabel(title: "mnemonicSize", content: payload.getMnemonicSize()?.humanReadableName() ?? "(none)")
                            SKLabel(title: "passphrase", content: payload.passphrase ?? "(none)")
                        } else {
                            SKLabel(title: "mnemonicSize", content: "")
                            SKLabel(title: "passphrase", content: "")
                        }
                        
                    } else if secret.type == .electrumMnemonic {
                        if let payload = cardState.currentSecretPayload as? ElectrumMnemonicPayload {
                            SKLabel(title: "mnemonicSize", content: payload.getMnemonicSize()?.humanReadableName() ?? "(none)")
                            SKLabel(title: "passphrase", content: payload.passphrase ?? "(none)")
                        } else {
                            SKLabel(title: "mnemonicSize", content: "")
                            SKLabel(title: "passphrase", content: "")
                        }
                        
                    }
                    
                    // MARK: action buttons for mnemonic
                    if secret.type == .bip39Mnemonic || (secret.type == .masterseed && secret.subtype == 0x01) || secret.type == .electrumMnemonic {
                        Spacer()
                            .frame(height: 30)
                        
                        HStack {
                            SKActionButtonSmall(title: "Seed", icon: "ic_bip85", isEnabled: $isSecretHeaderFetched) {
                                shouldShowSeedQR = false
                            }
                            
                            Spacer()
                            
                            SKActionButtonSmall(title: "SeedQR", icon: "ic_qr", isEnabled: $isSecretHeaderFetched) {
                                shouldShowSeedQR = true
                            }
                            
                        }
                        .padding([.leading, .trailing], 0)
                    }
                    
                    Spacer()
                        .frame(height: 30)
                    
                    // MARK: secret field
                    if let payload = cardState.currentSecretPayload {
                        SKSecretViewer(secretType: secret.type,
                                       shouldShowSeedQRCode: $shouldShowSeedQR,
                                       contentText:  .constant(payload.getContentString())
                        )
                    }else {
                        // empty secret field
                        SKSecretViewer(secretType: .password, // TODO: use something else?
                                       shouldShowSeedQRCode: $shouldShowSeedQR,
                                       contentText: .constant("Click on export to show secret data"))
                        
                    }
                    
                    Spacer()
                        .frame(height: 30)
                    
                    // MARK: action buttons
                    HStack {
                        
                        if let version = cardState.masterCardStatus?.protocolVersion, version >= 0x0002 {
                            // Only show delete button if supported by card
                            SKActionButtonSmall(title: String(localized: "delete"), icon: "ic_trash", isEnabled: .constant(true)) {
                                cardState.currentSecretHeader = secret
                                cardState.requestDeleteSecret()
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
