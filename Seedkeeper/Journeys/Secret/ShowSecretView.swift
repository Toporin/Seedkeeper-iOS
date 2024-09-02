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

struct ShowSecretView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    var secret: SeedkeeperSecretHeaderDto
    @State var shouldShowSeedQR: Bool = false
    @State var isSecretHeaderFetched: Bool = false
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Spacer()
                    .frame(height: 60)
                
                SatoText(text: "manageYourSecret", style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 16)
                
                SatoText(text: "secretInfoSubtitle", style: .SKStrongBodyDark)
                
                SKLabel(title: "label", content: secret.label)
                
                if secret.type == .bip39Mnemonic {
                    
                    SKLabel(title: "mnemonicSize", content: cardState.currentMnemonicCardData?.getMnemonicSize()?.humanReadableName() ?? "(none)")
                    
                    SKLabel(title: "passphrase", content: cardState.currentMnemonicCardData?.passphrase ?? "(none)")
                    
                } else if secret.type == .password {
                    
                    SKLabel(title: "Login", content: cardState.currentPasswordCardData?.login ?? "(none)")
                    
                    SKLabel(title: "Url", content: cardState.currentPasswordCardData?.url ?? "(none)")
                }
                
                if secret.type == .bip39Mnemonic {
                    Spacer()
                        .frame(height: 30)
                    
                    HStack {
                        SKActionButtonSmall(title: "Seed", icon: "ic_bip85", isEnabled: $isSecretHeaderFetched) {
                            guard let _ = cardState.currentMnemonicCardData else {
                                return
                            }
                            shouldShowSeedQR = false
                        }
                        
                        Spacer()
                        
                        SKActionButtonSmall(title: "SeedQR", icon: "ic_qr", isEnabled: $isSecretHeaderFetched) {
                            guard let _ = cardState.currentMnemonicCardData else {
                                return
                            }
                            shouldShowSeedQR = true
                        }
                        
                        if let version = cardState.cardStatus?.protocolVersion, version >= 0x0002 {
                            Spacer()
                            
                            SKActionButtonSmall(title: "Xpub", icon: "ic_xpub", isEnabled: $isSecretHeaderFetched) {
                                shouldShowSeedQR = false
                                cardState.requestGetXpub()
                            }
                        }
                    }
                    .padding([.leading, .trailing], 0)
                }
                
                Spacer()
                    .frame(height: 30)
                
                if let password = cardState.currentPasswordCardData?.password {
                    SKSecretViewer(secretType: .password, shouldShowQRCode: $shouldShowSeedQR, contentText:  .constant(password) )
                    
                } else if let mnemonicCardData = cardState.currentMnemonicCardData {
                    SKSecretViewer(secretType: .bip39Mnemonic,
                                   shouldShowQRCode: $shouldShowSeedQR,
                                   contentText: .constant(mnemonicCardData.mnemonic),
                                   mnemonicData: mnemonicCardData.getSeedQRContent())
                    
                } else {
                    SKSecretViewer(secretType: .unknown, shouldShowQRCode: $shouldShowSeedQR, contentText: .constant(""))
                    
                }
                
                Spacer()
                    .frame(height: 30)
                
                HStack {
                    if let version = cardState.cardStatus?.protocolVersion, version >= 0x0002 {
                        SKActionButtonSmall(title: String(localized: "delete"), icon: "ic_trash", isEnabled: .constant(true)) {
                            cardState.currentSecretHeader = secret
                            cardState.requestDeleteSecret()
                        }
                    }
                    
                    Spacer()
                    
                    SKActionButtonSmall(title: String(localized: "show"), icon: "ic_eye", isEnabled: .constant(true)) {
                        cardState.requestGetSecret(with: secret)
                        isSecretHeaderFetched = true
                    }
                }
                .padding([.leading, .trailing], 0)
                
                Spacer()
                    .frame(height: 30)

            }
            .padding([.leading, .trailing], Dimensions.lateralPadding)
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
