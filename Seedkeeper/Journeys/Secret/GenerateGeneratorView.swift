//
//  GenerateMnemonicView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 07/05/2024.
//

import Foundation
import SwiftUI
import SatochipSwift
import MnemonicSwift

enum GenerateBtnMode {
    case willGenerate
    case willImport
}

struct GeneratorModeNavData: Hashable {
    let generatorMode: GeneratorMode
    let secretCreationMode: SecretCreationMode
    
    init(generatorMode: GeneratorMode, secretCreationMode: SecretCreationMode) {
        self.generatorMode = generatorMode
        self.secretCreationMode = secretCreationMode
    }
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

struct MnemonicCardData {
    let mnemonic: String
    let passphrase: String?
    
    func getMnemonicSize() -> MnemonicSize? {
        let mnemonicWords = mnemonic.split(separator: " ")
        switch mnemonicWords.count {
        case 12:
            return .twelveWords
        case 18:
            return .eighteenWords
        case 24:
            return .twentyFourWords
        default:
            return nil
        }
    }
    
    func getSeedQRContent() -> String {
        let wordlist = SKMnemonicEnglish.words
        let indices = mnemonicToIndices(mnemonic: mnemonic, wordlist: wordlist)
        let combinedString = indices.map { String($0) }.joined(separator: " ")
        
        return combinedString
    }
    
    func getSeedQRImage() -> UIImage? {
        let wordlist = SKMnemonicEnglish.words
        let indices = mnemonicToIndices(mnemonic: mnemonic, wordlist: wordlist)
        let combinedString = indices.map { String($0) }.joined(separator: " ")

        guard let data = combinedString.data(using: .ascii) else { return nil }
        
        // Create a QR code filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func mnemonicToIndices(mnemonic: String, wordlist: [String]) -> [Int] {
        return mnemonic.split(separator: " ").compactMap { word in
            wordlist.firstIndex(of: String(word))
        }
    }
}

struct MnemonicPayload {
    var label: String
    var mnemonicSize: MnemonicSize
    var passphrase: String?
    var result: String
    
    func getPayloadBytes() -> [UInt8] {
        let mnemonicBytes = [UInt8](result.utf8)
        let mnemonicSize = UInt8(mnemonicBytes.count)
        
        var payload: [UInt8] = []
        payload.append(mnemonicSize)
        payload.append(contentsOf: mnemonicBytes)
        
        if let passphrase = passphrase {
            let passphraseBytes = [UInt8](passphrase.utf8)
            let passphraseSize = UInt8(passphraseBytes.count)
            payload.append(passphraseSize)
            payload.append(contentsOf: passphraseBytes)
        }

        return payload
    }
}

struct MnemonicManualImportPayload {
    var label: String
    var passphrase: String?
    var result: String
    
    func getPayloadBytes() -> [UInt8] {
        let mnemonicBytes = [UInt8](result.utf8)
        let mnemonicSize = UInt8(mnemonicBytes.count)
        
        var payload: [UInt8] = []
        payload.append(mnemonicSize)
        payload.append(contentsOf: mnemonicBytes)
        
        if let passphrase = passphrase {
            let passphraseBytes = [UInt8](passphrase.utf8)
            let passphraseSize = UInt8(passphraseBytes.count)
            payload.append(passphraseSize)
            payload.append(contentsOf: passphraseBytes)
        }

        return payload
    }
}

struct PasswordCardData {
    let password: String
    let login: String
    let url: String
}

struct PasswordPayload {
    var label: String
    var login: String?
    var url: String?
    var passwordLength: Double
    var result: String
    
    func getPayloadBytes() -> [UInt8] {
        let passwordBytes = [UInt8](result.utf8)
        let passwordSize = UInt8(passwordBytes.count)

        var payload: [UInt8] = []
        payload.append(passwordSize)
        payload.append(contentsOf: passwordBytes)
        
        if let login = login {
            let loginBytes = [UInt8](login.utf8)
            let loginSize = UInt8(loginBytes.count)
            payload.append(loginSize)
            payload.append(contentsOf: loginBytes)
        }

        if let url = url {
            let urlBytes = [UInt8](url.utf8)
            let urlSize = UInt8(urlBytes.count)
            payload.append(urlSize)
            payload.append(contentsOf: urlBytes)
        }

        return payload
    }
}

struct PasswordManualImportPayload {
    var label: String
    var login: String?
    var url: String?
    var result: String
    
    func getPayloadBytes() -> [UInt8] {
        let passwordBytes = [UInt8](result.utf8)
        let passwordSize = UInt8(passwordBytes.count)

        var payload: [UInt8] = []
        payload.append(passwordSize)
        payload.append(contentsOf: passwordBytes)
        
        if let login = login {
            let loginBytes = [UInt8](login.utf8)
            let loginSize = UInt8(loginBytes.count)
            payload.append(loginSize)
            payload.append(contentsOf: loginBytes)
        }

        if let url = url {
            let urlBytes = [UInt8](url.utf8)
            let urlSize = UInt8(urlBytes.count)
            payload.append(urlSize)
            payload.append(contentsOf: urlBytes)
        }

        return payload
    }
}

struct GenerateGeneratorView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    
    @Binding var homeNavigationPath: NavigationPath
    @State var generatorModeNavData: GeneratorModeNavData
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
    
    var canManualImportMnemonic: Bool {
        if let labelText = labelText  {
            return isMnemonicValid()
        } else {
            return false
        }
    }
    
    var canManualImportPassword: Bool {
        if let labelText = labelText {
            return !labelText.isEmpty && seedPhrase.count >= 8 && seedPhrase.count <= 16
        } else {
            return false
        }
    }
    
    private func isMnemonicValid() -> Bool {
        do {
            try Mnemonic.validate(mnemonic: seedPhrase)
            return true
        } catch {
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
    
    func getViewTitle() -> String {
        switch generatorModeNavData.generatorMode {
        case .mnemonic where generatorModeNavData.secretCreationMode == .generate:
            return String(localized: "generateMnemonicSecret")
        case .password where generatorModeNavData.secretCreationMode == .generate:
            return String(localized: "generatePasswordSecret")
        case .mnemonic where generatorModeNavData.secretCreationMode == .manualImport:
            return String(localized: "importMnemonicSecret")
        case .password where generatorModeNavData.secretCreationMode == .manualImport:
            return String(localized: "importPasswordSecret")
        default:
            return "n/a"
        }
    }
    
    func getViewSubtitle() -> String {
        switch generatorModeNavData.generatorMode {
        case .mnemonic where generatorModeNavData.secretCreationMode == .generate:
            return String(localized: "generateMnemonicSecretInfoSubtitle")
        case .password where generatorModeNavData.secretCreationMode == .generate:
            return String(localized: "generatePasswordSecretInfoSubtitle")
        case .mnemonic where generatorModeNavData.secretCreationMode == .manualImport:
            return String(localized: "importMnemonicSecretInfoSubtitle")
        case .password where generatorModeNavData.secretCreationMode == .manualImport:
            return String(localized: "importPasswordSecretInfoSubtitle")
        default:
            return "n/a"
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
                
                SatoText(text: self.getViewTitle(), style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 16)
                
                SatoText(text: self.getViewSubtitle(), style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 30)
                
                EditableCardInfoBox(mode: .text("[LABEL]"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { labelTextResult in
                    if case .text(let customLabelText) = labelTextResult {
                        labelText = customLabelText
                    }
                }
                
                Spacer()
                    .frame(height: 16)
                
                if generatorModeNavData.generatorMode == .mnemonic && generatorModeNavData.secretCreationMode != .manualImport {
                    EditableCardInfoBox(mode: .dropdown(self.mnemonicSizeOptions), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { options in
                        showPickerSheet = true
                    }
                } else if generatorModeNavData.generatorMode == .mnemonic && generatorModeNavData.secretCreationMode == .manualImport {
                    EditableCardInfoBox(mode: .fixedText("Mnemonic"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { options in
                        showPickerSheet = true
                    }
                }
                
                if generatorModeNavData.generatorMode == .password {
                    EditableCardInfoBox(mode: .text("Login"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { loginTextResult in
                        if case .text(let customLoginText) = loginTextResult {
                            loginText = customLoginText
                        }
                    }
                }
                
                if generatorModeNavData.generatorMode == .password {
                    Spacer()
                        .frame(height: 16)
                    
                    EditableCardInfoBox(mode: .text("Url"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { urlTextResult in
                        if case .text(let customUrlText) = urlTextResult {
                            urlText = customUrlText
                        }
                    }
                }
                
                if generatorModeNavData.generatorMode == .password && generatorModeNavData.secretCreationMode != .manualImport {
                    Spacer()
                        .frame(height: 16)
                    
                    PasswordGeneratorBox(options: passwordOptions)
                }
                
                if generatorModeNavData.generatorMode == .mnemonic {
                    
                    Spacer()
                        .frame(height: 16)
                    
                    EditableCardInfoBox(mode: .text("Passphrase"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { passphraseTextResult in
                        if case .text(let customPassphraseText) = passphraseTextResult {
                            passphraseText = customPassphraseText
                        }
                    }
                }
                
                Spacer()
                    .frame(height: generatorModeNavData.generatorMode == .password ? 16 : 60)
                
                SKSecretViewer(shouldShowQRCode: .constant(false), contentText: $seedPhrase, isEditable: generatorModeNavData.secretCreationMode == .manualImport) { result in
                    // seedPhrase = result
                }

                Spacer()
                    .frame(height: 30)
                
                Button(action: {
                    homeNavigationPath.removeLast()
                }) {
                    SatoText(text: "back", style: .SKMenuItemTitle)
                }
                
                Spacer()
                    .frame(height: 16)
                
                if generatorModeNavData.secretCreationMode == .manualImport {
                    SKButton(text: String(localized: "import"), style: .regular, horizontalPadding: 66, isEnabled: true, action: {
                        if generatorModeNavData.generatorMode == .mnemonic, canManualImportMnemonic {
                            
                            cardState.mnemonicManualImportPayload = MnemonicManualImportPayload(label: labelText!,
                                                              passphrase: passphraseText,
                                                              result: seedPhrase)
                            
                            cardState.requestManualImportSecret(secretType: .bip39Mnemonic)
                        }
                        
                        if generatorModeNavData.generatorMode == .password, canManualImportPassword {
                            
                            cardState.passwordManualImportPayload = PasswordManualImportPayload(label: labelText!,
                                                              login: loginText,
                                                              url: urlText,
                                                              result: seedPhrase)
                            
                            cardState.requestManualImportSecret(secretType: .password)
                        }
                    })
                } else {
                    SKButton(text: continueBtnTitle, style: .regular, horizontalPadding: 66, isEnabled: canGenerateMnemonic || canGeneratePassword, action: {
                        if generateBtnMode == .willGenerate {
                            
                            if generatorModeNavData.generatorMode == .mnemonic, canGenerateMnemonic {
                                
                                seedPhrase = generateMnemonic() ?? "Failed to generate mnemonic"
                                
                                mnemonicPayload = MnemonicPayload(label: labelText!,
                                                                  mnemonicSize: MnemonicSize(rawValue: mnemonicSizeOptions.selectedOption!)!,
                                                                  passphrase: passphraseText,
                                                                  result: seedPhrase)
                            }
                            
                            if generatorModeNavData.generatorMode == .password, canGeneratePassword {
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
                }
                
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
                SatoText(text: generatorModeNavData.secretCreationMode == .manualImport ? "importSecret" : "generateSecret", style: .lightTitleDark)
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

