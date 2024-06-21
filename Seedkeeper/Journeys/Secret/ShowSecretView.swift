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
                    
                    SKLabel(title: "login", content: cardState.currentPasswordCardData?.login ?? "(none)")
                    
                    SKLabel(title: "Url:", content: cardState.currentPasswordCardData?.url ?? "(none)")
                }
                
                if secret.type == .bip39Mnemonic {
                    Spacer()
                        .frame(height: 30)
                    
                    HStack {
                        SKActionButtonSmall(title: "Seed", icon: "ic_bip85") {
                            guard let _ = cardState.currentMnemonicCardData else {
                                return
                            }
                            shouldShowSeedQR = false
                        }
                        
                        Spacer()
                        
                        SKActionButtonSmall(title: "SeedQR", icon: "ic_qr") {
                            guard let _ = cardState.currentMnemonicCardData else {
                                return
                            }
                            shouldShowSeedQR = true
                        }
                        
                        if let version = cardState.cardStatus?.protocolVersion, version >= 0x0002 {
                            Spacer()
                            
                            SKActionButtonSmall(title: "Xpub", icon: "ic_xpub") {
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
                    SKSecretViewer(shouldShowQRCode: $shouldShowSeedQR, contentText:  .constant(password) )
                    
                } else if let mnemonicCardData = cardState.currentMnemonicCardData {
                    SKSecretViewer(shouldShowQRCode: $shouldShowSeedQR, contentText: shouldShowSeedQR ? .constant(mnemonicCardData.getSeedQRContent()) : .constant(mnemonicCardData.mnemonic))
                    
                } else {
                    SKSecretViewer(shouldShowQRCode: $shouldShowSeedQR, contentText: .constant(""))
                    
                }
                
                Spacer()
                    .frame(height: 30)
                
                HStack {
                    if let version = cardState.cardStatus?.protocolVersion, version >= 0x0002 {
                        SKActionButtonSmall(title: "delete", icon: "ic_trash") {
                            cardState.currentSecretHeader = secret
                            cardState.requestDeleteSecret()
                        }
                    }
                    
                    Spacer()
                    
                    SKActionButtonSmall(title: "show", icon: "ic_eye") {
                        cardState.requestGetSecret(with: secret)
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
