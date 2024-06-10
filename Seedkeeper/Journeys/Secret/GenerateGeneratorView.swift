//
//  GenerateMnemonicView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 07/05/2024.
//

import Foundation
import SwiftUI
import SatochipSwift

enum GenerateBtnMode {
    case willGenerate
    case willImport
}

enum GeneratorMode: String, CaseIterable, Hashable {
    case mnemonic
    case password
    
    var humanReadableName: String {
        switch self {
        case .mnemonic:
            return String(localized: "mnemonicPhrase")
        case .password:
            return String(localized: "loginPasswordPhrase")
        }
    }
}

enum MnemonicSize: String, CaseIterable, Hashable {
    case twelveWords
    case eighteenWords
    case twentyFourWords
    
    var humanReadableName: String {
        switch self {
        case .twelveWords:
            return String(localized: "12words")
        case .eighteenWords:
            return String(localized: "18words")
        case .twentyFourWords:
            return String(localized: "24words")
        }
    }
        
    func toBits() -> Int {
        switch self {
        case .twelveWords:
            return 128
        case .eighteenWords:
            return 192
        case .twentyFourWords:
            return 256
        }
    }
}

struct MnemonicPayload {
    var label: String
    var mnemonicSize: MnemonicSize
    var passphrase: String?
    var result: String
}

struct PasswordPayload {
    var label: String
    var login: String?
    var url: String?
    var passwordLength: Double
    var result: String
}

struct GenerateGeneratorView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    
    @Binding var homeNavigationPath: NavigationPath
    @State var generatorMode: GeneratorMode
    @State private var showPickerSheet = false
    @State private var generateBtnMode = GenerateBtnMode.willGenerate
    
    @State var passwordOptions = PasswordOptions()
    
    @State private var passphraseText: String?
    @State private var labelText: String?
    @State private var loginText: String?
    @State private var urlText: String?
    
    @State private var mnemonicPayload: MnemonicPayload?
    @State private var passwordPayload: PasswordPayload?
        
    // Mnemonic :
    // > Label
    // > MnemonicSize
    // > Passphrase
    
    // Password :
    // > Label
    // > Login
    // > Url
    // > PasswordLength
    
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
    @State var mnemonicSizeOptions = PickerOptions(placeHolder: String(localized: "selectMnemonicSize"), items: MnemonicSize.allCases.map { $0.rawValue })
    
    var canGeneratePassword: Bool {
        if let labelText = labelText {
            return !labelText.isEmpty && passwordOptions.userSelectedAtLeastOneIncludeOption()
        } else {
            return false
        }
    }
    
    var canGenerateMnemonic: Bool {
        if let labelText = labelText, let _ = mnemonicSizeOptions.selectedOption {
            return !labelText.isEmpty
        } else {
            return false
        }
    }
    
    func generateMnemonic() -> String? {
        do {
            
            guard let mnemonicSizeOptions = mnemonicSizeOptions.selectedOption,
                  let mnemonicSize = MnemonicSize(rawValue: mnemonicSizeOptions)?.toBits() else {
                return nil
            }

            let mnemonic = try Mnemonic.generateMnemonic(strength: mnemonicSize)
            return mnemonic
            
        } catch {
            print("Error generating mnemonic: \(error)")
        }
        return nil
    }
    
    func generatePassword(options: PasswordOptions) -> String {
        var characterSet = ""
        
        if options.includeLowercase {
            characterSet += "abcdefghijklmnopqrstuvwxyz"
        }
        
        if options.includeUppercase {
            characterSet += "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        }
        
        if options.includeNumbers {
            characterSet += "0123456789"
        }
        
        if options.includeSymbols {
            characterSet += "!@#$%^&*()-_=+{}[]|;:'\",.<>?/`~"
        }
        
        guard !characterSet.isEmpty else {
            return "Please select at least one character set"
        }
        
        let length = Int(options.passwordLength)
        var password = ""
        
        for _ in 0..<length {
            if let randomCharacter = characterSet.randomElement() {
                password.append(randomCharacter)
            }
        }
        
        return password
    }
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Spacer()
                    .frame(height: 60)
                
                SatoText(text: generatorMode == .mnemonic ? "generateMnemonicSecret" : "generatePasswordSecret", style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 16)
                
                SatoText(text: generatorMode == .mnemonic ? "generateMnemonicSecretInfoSubtitle" : "generatePasswordSecretInfoSubtitle", style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 30)
                
                EditableCardInfoBox(mode: .text("[LABEL]"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { labelTextResult in
                    if case .text(let customLabelText) = labelTextResult {
                        labelText = customLabelText
                    }
                }
                
                Spacer()
                    .frame(height: 16)
                
                if generatorMode == .mnemonic {
                    EditableCardInfoBox(mode: .dropdown(self.mnemonicSizeOptions), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { options in
                        showPickerSheet = true
                    }
                }
                
                if generatorMode == .password {
                    EditableCardInfoBox(mode: .text("Login"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { loginTextResult in
                        if case .text(let customLoginText) = loginTextResult {
                            loginText = customLoginText
                        }
                    }
                }
                
                if generatorMode == .password {
                    Spacer()
                        .frame(height: 16)
                    
                    EditableCardInfoBox(mode: .text("Url"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { urlTextResult in
                        if case .text(let customUrlText) = urlTextResult {
                            urlText = customUrlText
                        }
                    }
                }
                
                if generatorMode == .password {
                    Spacer()
                        .frame(height: 16)
                    
                    PasswordGeneratorBox(options: passwordOptions)
                }
                
                if generatorMode == .mnemonic {
                    
                    Spacer()
                        .frame(height: 16)
                    
                    EditableCardInfoBox(mode: .text("Passphrase"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { passphraseTextResult in
                        if case .text(let customPassphraseText) = passphraseTextResult {
                            passphraseText = customPassphraseText
                        }
                    }
                }
                
                Spacer()
                    .frame(height: generatorMode == .password ? 16 : 60)
                
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
                
                SKButton(text: continueBtnTitle, style: .regular, horizontalPadding: 66, isEnabled: canGenerateMnemonic || canGeneratePassword, action: {
                    if generateBtnMode == .willGenerate {
                        
                        if generatorMode == .mnemonic, canGenerateMnemonic {
                            
                            seedPhrase = generateMnemonic() ?? "Failed to generate mnemonic"
                            
                            mnemonicPayload = MnemonicPayload(label: labelText!,
                                                              mnemonicSize: MnemonicSize(rawValue: mnemonicSizeOptions.selectedOption!)!,
                                                              passphrase: passphraseText,
                                                              result: seedPhrase)
                        }
                        
                        if generatorMode == .password, canGeneratePassword {
                            let password = generatePassword(options: passwordOptions)
                            
                            seedPhrase = password
                            
                            passwordPayload = PasswordPayload(label: labelText!,
                                                              login: loginText,
                                                              url: urlText,
                                                              passwordLength: passwordOptions.passwordLength,
                                                              result: seedPhrase)
                        }
                        
                    } else if generateBtnMode == .willImport {
                        if let mnemonicPayload = self.mnemonicPayload {
                            print("will import mnemonic")
                            cardState.mnemonicPayloadToImportOnCard = mnemonicPayload
                            cardState.requestAddSecret(secretType: .bip39Mnemonic)
                        }
                        
                        if let passwordPayload = self.passwordPayload {
                            print("will import password")
                            cardState.passwordPayloadToImportOnCard = passwordPayload
                            cardState.requestAddSecret(secretType: .password)
                        }
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
                SatoText(text: "generateSecretViewTitle", style: .lightTitleDark)
            }
        }
        .sheet(isPresented: $showPickerSheet) {
            OptionSelectorView(pickerOptions: $mnemonicSizeOptions)
        }
        .onDisappear {
            cardState.cleanPayloadToImportOnCard()
        }
    }
}

