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

struct GeneratePasswordView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    
    @Binding var homeNavigationPath: NavigationPath
    @State var generatorModeNavData: GeneratorModeNavData
    @State private var showPickerSheet = false
    
    @StateObject var passwordOptions = PasswordOptions()
    
    @State private var labelText: String?
    @State private var loginText: String?
    @State private var urlText: String?
    
    @State var password = ""
    @State private var passwordPayload: PasswordPayload?
    
    // Password :
    // > Label
    // > Login
    // > Url
    // > PasswordLength
            
    var canGeneratePassword: Bool {
        if let labelText = labelText {
            return !labelText.isEmpty && passwordOptions.userSelectedAtLeastOneIncludeOption() && generatorModeNavData.generatorMode == .password
        } else {
            return false
        }
    }
    
    var canManualImportPassword: Bool {
        if let labelText = labelText {
            return !labelText.isEmpty && password.count >= 1
        } else {
            return false
        }
    }
    
    private func getMemorableWordsFromTextFile() -> [String] {
        guard let path = Bundle.main.path(forResource: "memorable-pwd", ofType: "txt") else {
            return []
        }
        
        do {
            let contents = try String(contentsOfFile: path)
            return contents.components(separatedBy: "\n")
        } catch {
            return []
        }
    }
    
    private func formatRandomWord(randomWord: String, isUppercased: Bool, shouldIncludeNumber: Bool) -> String {
        var randomWordResult = isUppercased ? randomWord.showWithFirstLetterAsCapital() : randomWord
        if shouldIncludeNumber {
            randomWordResult.append("\(Int.random(in: 0...9))")
        }
        return randomWordResult
    }
        
    func generatePassword(options: PasswordOptions) -> String {
        let numberSet = "0123456789"
        let symbolSet = "!@#$%^&*()-_=+{}[]|;:'\",.<>?/`~"
        let upperCaseSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowerCaseSet = "abcdefghijklmnopqrstuvwxyz"
        
        var characterSet = ""
        
        if options.isMemorablePassword {
            let length = Int(options.passwordLength)
            var password = ""
            let words = self.getMemorableWordsFromTextFile()
            
            for _ in 0..<length {
                if let randomWord = words.randomElement() {
                    
                    let separator = options.includeSymbols ? symbolSet.randomElement() ?? "!" : "-"
                    
                    let randomWordResult = formatRandomWord(randomWord: randomWord,
                                                            isUppercased: options.includeUppercase,
                                                            shouldIncludeNumber: options.includeNumbers)
                    
                    password.append("\(randomWordResult)\(separator)")
                }
            }
            
            password.removeLast()
            return password
        }
        
        if options.includeLowercase {
            characterSet += lowerCaseSet
        }
        
        if options.includeUppercase {
            characterSet += upperCaseSet
        }
        
        if options.includeNumbers {
            characterSet += numberSet
        }
        
        if options.includeSymbols {
            characterSet += symbolSet
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
        case .password where generatorModeNavData.secretCreationMode == .generate:
            return String(localized: "generatePasswordSecret")
        case .password where generatorModeNavData.secretCreationMode == .manualImport:
            return String(localized: "importPasswordSecret")
        default:
            return "n/a"
        }
    }
    
    func getViewSubtitle() -> String {
        switch generatorModeNavData.generatorMode {
        case .password where generatorModeNavData.secretCreationMode == .generate:
            return String(localized: "generatePasswordSecretInfoSubtitle")
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
            ScrollViewReader { scrollValue in
                
                ScrollView {
                    
                    VStack {
                        
                        Spacer()
                            .frame(height: 60)
                        
                        SatoText(text: self.getViewTitle(), style: .SKStrongBodyDark)
                        
                        Spacer()
                            .frame(height: 16)
                        
                        SatoText(text: self.getViewSubtitle(), style: .SKStrongBodyDark)
                        
                        Spacer()
                            .frame(height: 30)
                        
                        EditableCardInfoBox(mode: .text("Label"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { labelTextResult in
                            if case .text(let customLabelText) = labelTextResult {
                                labelText = customLabelText
                            }
                        }
                        
                        Spacer()
                            .frame(height: 16)
                        
                        if generatorModeNavData.generatorMode == .password {
                            EditableCardInfoBox(mode: .text("Login"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5, shouldDisplaySuggestions: true,
                                    action:
                                    { loginTextResult in
                                        if case .text(let customLoginText) = loginTextResult {
                                            loginText = customLoginText
                                        }
                                    },
                                    focusAction: {
                                        withAnimation {
                                            scrollValue.scrollTo(0, anchor: .top)
                                        }
                                    }
                            )
                            .id(0)
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
                        
                        Spacer()
                            .frame(height: generatorModeNavData.generatorMode == .password ? 16 : 60)
                        
                        SKSecretViewer(secretType: .unknown, shouldShowQRCode: .constant(false), contentText: $password, isEditable: generatorModeNavData.secretCreationMode == .manualImport) { result in
                        }

                        Spacer()
                            .frame(height: 16)
                        
                        
                        if generatorModeNavData.secretCreationMode == .manualImport {
                            // Import button for manual import
                            SKButton(text: String(localized: "import"), style: .regular, horizontalPadding: 66, isEnabled: canManualImportPassword, action: {
                                                                    
                                    cardState.passwordPayloadToImportOnCard = PasswordPayload(label: labelText!,
                                                                                            password: password,
                                                                                            login: loginText,
                                                                                            url: urlText)
                                    
                                    cardState.requestAddSecret(secretType: .password)
                            })
                        } else {
                            // (re)generate and import buttons
                            HStack(alignment: .center, spacing: 0) {
                                Spacer()
                                
                                HStack(alignment: .center, spacing: 12) {
                                    
                                    SKButton(
                                        text: String(localized: "generate"),
                                        style: .regular,
                                        horizontalPadding: 20,
                                        isEnabled: canGeneratePassword,
                                        action: {
                                                password = generatePassword(options: passwordOptions)
                                                passwordPayload = PasswordPayload(label: labelText!,
                                                                                  password: password,
                                                                                  login: loginText,
                                                                                  url: urlText)
                                    })
                                    
                                    SKButton(
                                        text: String(localized: "import"),
                                        style: .regular, 
                                        horizontalPadding: 20,
                                        isEnabled: canManualImportPassword,
                                        action: {
                                            if let passwordPayload = self.passwordPayload {
                                                print("will import password")
                                                cardState.passwordPayloadToImportOnCard = passwordPayload
                                                cardState.requestAddSecret(secretType: .password)
                                            }
                                    })
                                }
                                
                                Spacer()
                            }

                        }
                        
                        Spacer().frame(height: 16)
                        
                    }
                    .padding([.leading, .trailing], Dimensions.lateralPadding)
                }
            }
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
        .onDisappear {
            cardState.cleanPayloadToImportOnCard()
        }
    }
}

// MARK: Payload types

struct PasswordPayload {
    var label: String
    var password: String
    var login: String?
    var url: String?
    
    func getPayloadBytes() -> [UInt8] {
        let passwordBytes = [UInt8](password.utf8)
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
