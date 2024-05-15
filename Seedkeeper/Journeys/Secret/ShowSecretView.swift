//
//  ShowSecretView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 04/05/2024.
//

import Foundation
import SwiftUI

struct ShowSecretView: View {
    // MARK: - Properties
    @Binding var homeNavigationPath: NavigationPath
    var secret: String
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Spacer()
                    .frame(height: 60)
                
                SatoText(text: "**manageYourSecret**", style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 16)
                
                SatoText(text: "secretInfoSubtitle", style: .SKStrongBodyDark)
                
                SKLabel(title: "Label", content: secret)
                
                SKLabel(title: "MnemonicSize", content: "(none)")
                
                SKLabel(title: "Passphrase", content: "(none)")
                
                Spacer()
                    .frame(height: 30)
                
                HStack {
                    SKActionButtonSmall(title: "BIP85", icon: "ic_bip85") {
                        
                    }
                    
                    Spacer()
                    
                    SKActionButtonSmall(title: "SeedQR", icon: "ic_qr") {
                        
                    }
                    
                    Spacer()
                    
                    SKActionButtonSmall(title: "Xpub", icon: "ic_xpub") {
                        
                    }
                }
                .padding([.leading, .trailing], 0)
                
                Spacer()
                    .frame(height: 30)
                
                SKSecretViewer(shouldShowQRCode: false, contentText: "author canvas lecture illegal rabbit aware walk visit thing found naive interest")
                
                Spacer()
                    .frame(height: 30)
                
                HStack {
                    SKActionButtonSmall(title: "Delete", icon: "ic_trash") {
                        
                    }
                    
                    Spacer()
                    
                    SKActionButtonSmall(title: "Show", icon: "ic_eye") {
                        
                    }
                }
                .padding([.leading, .trailing], 0)
                
                Spacer()
                    .frame(height: 30)

            }
            .padding([.leading, .trailing], Dimensions.lateralPadding)
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
    @State var shouldShowQRCode: Bool = false
    var contentText: String
    
    var contentTextClear: String {
        return showText ? contentText : String(repeating: "*", count: contentText.count)
    }
    
    func convertStringToQRCode() -> Image {
        let data = contentText.data(using: .ascii)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = filter?.outputImage?.transformed(by: transform)
        
        return Image(uiImage: UIImage(ciImage: image!))
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Colors.purpleBtn.opacity(0.2))
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        // copy to clipboard
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
                
                Spacer()
                
                if shouldShowQRCode {
                    convertStringToQRCode()
                        .resizable()
                        .frame(width: 200, height: 200)
                        .padding()
                } else {
                    Text(contentTextClear)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
        }
        .frame(width: .infinity, height: .infinity)
    }
}

