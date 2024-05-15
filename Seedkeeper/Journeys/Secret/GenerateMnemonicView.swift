//
//  GenerateMnemonicView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 07/05/2024.
//

import Foundation
import SwiftUI

enum GenerateBtnMode {
    case willGenerate
    case willImport
}

struct GenerateMnemonicView: View {
    // MARK: - Properties
    @Binding var homeNavigationPath: NavigationPath
    @State private var showPickerSheet = false
    @State private var generateBtnMode = GenerateBtnMode.willGenerate
    @State var seedPhrase = "" {
        didSet {
            if seedPhrase.isEmpty {
                generateBtnMode = .willGenerate
            } else {
                generateBtnMode = .willImport
            }
        }
    }
    var continueBtnTitle: String {
        switch generateBtnMode {
        case .willGenerate:
            return String(localized: "generate")
        case .willImport:
            return String(localized: "import")
        }
    }
    @State var mnemonicSizeOptions = PickerOptions(placeHolder: "mnemonicSize", items: ["12 words","18 words", "24 words"])
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Spacer()
                    .frame(height: 60)
                
                SatoText(text: "**generateMnemonicSecret**", style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 16)
                
                SatoText(text: "generateMnemonicSecretInfoSubtitle", style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 30)
                
                EditableCardInfoBox(mode: .text("[LABEL]"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { text in
                    print(text)
                }
                
                Spacer()
                    .frame(height: 16)
                
                EditableCardInfoBox(mode: .dropdown(self.mnemonicSizeOptions), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { options in
                    showPickerSheet = true
                }
                
                Spacer()
                    .frame(height: 16)
                
                EditableCardInfoBox(mode: .text("Passphrase"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { text in
                    print(text)
                }
                
                Spacer()
                    .frame(height: 60)
                
                SKSecretViewer(shouldShowQRCode: false, contentText: seedPhrase)

                Spacer()
                    .frame(height: 30)
                
                Button(action: {
                    homeNavigationPath.removeLast()
                }) {
                    SatoText(text: "back", style: .SKMenuItemTitle)
                }
                
                Spacer()
                    .frame(height: 16)
                
                SKButton(text: continueBtnTitle, style: .regular, horizontalPadding: 66, action: {
                    if generateBtnMode == .willGenerate {
                        seedPhrase = "author canvas lecture illegal rabbit aware walk visit thing found naive interest"
                    } else if generateBtnMode == .willImport {
                        homeNavigationPath.append(NavigationRoutes.generateSuccess)
                    }
                })
                
                Spacer().frame(height: 16)

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
                SatoText(text: "generateMnemonicSecretViewTitle", style: .lightTitleDark)
            }
        }
        .sheet(isPresented: $showPickerSheet) {
            OptionSelectorView(pickerOptions: $mnemonicSizeOptions)
        }
    }
}

