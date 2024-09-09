//
//  SKSecretViewer.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 21/06/2024.
//

import Foundation
import SwiftUI
import QRCode

enum SecretType {
    case unknown
    case password
    case bip39Mnemonic
    case secret2FA
    case masterseedMnemonic
    case masterseed
    case electrumMnemonic
}

struct SKSecretViewer: View {
    @State private var showText: Bool = false
    var secretType: SecretType
    @Binding var shouldShowQRCode: Bool
    @Binding var contentText: String {
        didSet {
            print("contentText: \(contentText)")
        }
    }
    var isEditable: Bool = false
    var userInputResult: ((String) -> Void)? = nil
    var mnemonicData: [UInt8]? = nil
    
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
    
    private func generateMnemonicSeedQR(with data: [UInt8]) -> UIImage? {
        do {
            let doc = try QRCode.Document(Data(data))
            doc.design.foregroundColor(Color.black.cgColor!)
            doc.design.backgroundColor(Color.white.cgColor!)
            let generated = try doc.cgImage(CGSize(width: 200, height: 200))
            let image = UIImage(cgImage: generated)
            return image
        } catch {
            print("Failed to generate QR code: \(error.localizedDescription)")
            return nil
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Colors.purpleBtn.opacity(0.2))
            
            VStack {
                
                    HStack {
                        Spacer()
                        if !isEditable, secretType == .password {
                            Button(action: {
                                shouldShowQRCode.toggle()
                            }) {
                                Image("ic_qr")
                                    .foregroundColor(.white)
                                    .padding(5)
                            }
                        }
                        
                        if !shouldShowQRCode {
                            Button(action: {
                                UIPasteboard.general.string = contentText
                            }) {
                                Image(systemName: "square.on.square")
                                    .foregroundColor(.white)
                                    .padding(5)
                            }
                            if !isEditable {
                                Button(action: {
                                    showText.toggle()
                                }) {
                                    Image(systemName: showText ? "eye.slash" : "eye")
                                        .foregroundColor(.white)
                                        .padding(5)
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                
                Spacer()
                
                if isEditable {
                    TextField(String(localized: "placeholder.yourSecret"), text: $contentText, onEditingChanged: { (editingChanged) in
                        if editingChanged {
                            print("TextField focused")
                        } else {
                            print("TextField focus removed")
                            userInputResult?(contentText)
                        }
                        
                    })
                        .padding()
                        .background(.clear)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .disableAutocorrection(true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if shouldShowQRCode {
                        if secretType == .bip39Mnemonic || secretType == .masterseedMnemonic,
                           let mnemonicData = self.mnemonicData,
                           let seedQRImage = self.generateMnemonicSeedQR(with: mnemonicData)  {
                            
                            Image(uiImage: seedQRImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 219, height: 219, alignment: .center)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            
                        } else if secretType == .password,
                                  let cgImage = self.getQRfromText(text: contentText) {
                            
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
