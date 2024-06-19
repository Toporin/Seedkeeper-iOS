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
                    
                    SKLabel(title: "mnemonicSize", content: cardState.currentMnemonicCardData?.getMnemonicSize()?.humanReadableName ?? "(none)")
                    
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
                        SKActionButtonSmall(title: "Delete", icon: "ic_trash") {
                            cardState.currentSecretHeader = secret
                            cardState.requestDeleteSecret()
                        }
                    }
                    
                    Spacer()
                    
                    SKActionButtonSmall(title: "Show", icon: "ic_eye") {
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

struct SKLabel: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                SatoText(text: title, style: .SKStrongBodyDark)
                Spacer()
            }
            Text(content)
                .font(.custom("OpenSans-Regular", size: 16))
                .lineSpacing(24)
                .multilineTextAlignment(.leading)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 33, maxHeight: 33)
                .background(Colors.purpleBtn.opacity(0.5))
                .cornerRadius(20)
        }
        
    }
}

struct SKActionButtonSmall: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                    .font(.custom("OpenSans-SemiBold", size: 18))
                    .lineLimit(1)
                    .padding(.leading, 10)
                
                Spacer()
                    .frame(width: 4)
                
                Image(icon)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
                    .padding(.trailing, 10)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40)
            .background(Colors.purpleBtn)
            .cornerRadius(20)
        }
    }
}

struct SKSecretViewer: View {
    @State private var showText: Bool = false
    @Binding var shouldShowQRCode: Bool
    @Binding var contentText: String {
        didSet {
            print("contentText: \(contentText)")
        }
    }
    var isEditable: Bool = false
    var userInputResult: ((String) -> Void)? = nil
    
    var contentTextClear: String {
        return showText ? contentText : String(repeating: "*", count: contentText.count)
    }
    
    public func getQRfromText(text: String) -> CGImage? {
        do {
            let doc = try QRCode.Document(utf8String: text, errorCorrection: .high)
            doc.design.foregroundColor(Color.black.cgColor!)
            doc.design.backgroundColor(Color.white.cgColor!)
            let generated = try doc.cgImage(CGSize(width: 200, height: 200))
            return generated
        } catch {
            return nil
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Colors.purpleBtn.opacity(0.2))
            
            VStack {
                if !shouldShowQRCode {
                    HStack {
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = contentText
                        }) {
                            Image(systemName: "square.on.square")
                                .foregroundColor(.white)
                                .padding(5)
                        }
                        Button(action: {
                            showText.toggle()
                        }) {
                            Image(systemName: showText ? "eye.slash" : "eye")
                                .foregroundColor(.white)
                                .padding(5)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                }
                
                Spacer()
                
                if isEditable {
                    TextField("", text: $contentText, onEditingChanged: { (editingChanged) in
                        if editingChanged {
                            print("TextField focused")
                        } else {
                            print("TextField focus removed")
                            userInputResult?(contentText)
                        }
                        
                    })
                        .padding()
                        .background(.clear)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if shouldShowQRCode {
                        if let cgImage = self.getQRfromText(text: contentText) {
                            Image(uiImage: UIImage(cgImage: cgImage))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 219, height: 219, alignment: .center)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    } else {
                        Text(contentTextClear)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                }
                
                Spacer()
            }
        }
        .frame(width: .infinity, height: .infinity)
    }
}

