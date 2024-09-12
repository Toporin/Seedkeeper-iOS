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

struct GenerateMnemonicView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    
    @Binding var homeNavigationPath: NavigationPath
    @State var generatorModeNavData: GeneratorModeNavData
    @State private var showPickerSheet = false
    @State private var generateBtnMode = GenerateBtnMode.willGenerate
    
//    @StateObject var passwordOptions = PasswordOptions()
    
    @State private var passphraseText: String?
    @State private var labelText: String?
//    @State private var loginText: String?
//    @State private var urlText: String?
    
    @State private var mnemonicPayload: MnemonicPayload?
//    @State private var passwordPayload: PasswordPayload?

    // Mnemonic :
    // > Label
    // > MnemonicSize
    // > Passphrase
    // > WalletDescriptor
    
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
    
    @State var mnemonicSizeOptions = PickerOptions(placeHolder: String(localized: "selectMnemonicSize"), items: MnemonicSize.self)
        
//    var canGeneratePassword: Bool {
//        if let labelText = labelText {
//            return !labelText.isEmpty && passwordOptions.userSelectedAtLeastOneIncludeOption() && generatorModeNavData.generatorMode == .password
//        } else {
//            return false
//        }
//    }
    
    var canGenerateMnemonic: Bool {
        if let labelText = labelText, let _ = mnemonicSizeOptions.selectedOption, generatorModeNavData.generatorMode == .mnemonic {
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
    
//    var canManualImportPassword: Bool {
//        if let labelText = labelText {
//            return !labelText.isEmpty && seedPhrase.count >= 1
//        } else {
//            return false
//        }
//    }
    
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
            
            guard let mnemonicSizeOptions = mnemonicSizeOptions.selectedOption else {
                return nil
            }
            
            let mnemonicSize = mnemonicSizeOptions.toBits()
            let mnemonic = try Mnemonic.generateMnemonic(strength: mnemonicSize)
            return mnemonic
            
        } catch {
            print("Error generating mnemonic: \(error)")
        }
        return nil
    }
    
//    private func getMemorableWordsFromTextFile() -> [String] {
//        guard let path = Bundle.main.path(forResource: "memorable-pwd", ofType: "txt") else {
//            return []
//        }
//        
//        do {
//            let contents = try String(contentsOfFile: path)
//            return contents.components(separatedBy: "\n")
//        } catch {
//            return []
//        }
//    }
    
//    private func formatRandomWord(randomWord: String, isUppercased: Bool, shouldIncludeNumber: Bool) -> String {
//        var randomWordResult = isUppercased ? randomWord.showWithFirstLetterAsCapital() : randomWord
//        if shouldIncludeNumber {
//            randomWordResult.append("\(Int.random(in: 0...9))")
//        }
//        return randomWordResult
//    }
        
//    func generatePassword(options: PasswordOptions) -> String {
//        let numberSet = "0123456789"
//        let symbolSet = "!@#$%^&*()-_=+{}[]|;:'\",.<>?/`~"
//        
//        var characterSet = ""
//        
//        if options.isMemorablePassword {
//            let length = Int(options.passwordLength)
//            var password = ""
//            let words = self.getMemorableWordsFromTextFile()
//            
//            for _ in 0..<length {
//                if let randomWord = words.randomElement() {
//                    
//                    let separator = options.includeSymbols ? symbolSet.randomElement() ?? "!" : "-"
//                    
//                    let randomWordResult = formatRandomWord(randomWord: randomWord,
//                                                            isUppercased: options.includeUppercase,
//                                                            shouldIncludeNumber: options.includeNumbers)
//                    
//                    password.append("\(randomWordResult)\(separator)")
//                }
//            }
//            
//            password.removeLast()
//            return password
//        }
//        
//        if options.includeLowercase {
//            characterSet += "abcdefghijklmnopqrstuvwxyz"
//        }
//        
//        if options.includeUppercase {
//            characterSet += "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
//        }
//        
//        if options.includeNumbers {
//            characterSet += numberSet
//        }
//        
//        if options.includeSymbols {
//            characterSet += symbolSet
//        }
//        
//        guard !characterSet.isEmpty else {
//            return "Please select at least one character set"
//        }
//        
//        let length = Int(options.passwordLength)
//        var password = ""
//        
//        for _ in 0..<length {
//            if let randomCharacter = characterSet.randomElement() {
//                password.append(randomCharacter)
//            }
//        }
//        
//        return password
//    }
    
    func getViewTitle() -> String {
        switch generatorModeNavData.generatorMode {
        case .mnemonic where generatorModeNavData.secretCreationMode == .generate:
            return String(localized: "generateMnemonicSecret")
//        case .password where generatorModeNavData.secretCreationMode == .generate:
//            return String(localized: "generatePasswordSecret")
        case .mnemonic where generatorModeNavData.secretCreationMode == .manualImport:
            return String(localized: "importMnemonicSecret")
//        case .password where generatorModeNavData.secretCreationMode == .manualImport:
//            return String(localized: "importPasswordSecret")
        default:
            return "n/a"
        }
    }
    
    func getViewSubtitle() -> String {
        switch generatorModeNavData.generatorMode {
        case .mnemonic where generatorModeNavData.secretCreationMode == .generate:
            return String(localized: "generateMnemonicSecretInfoSubtitle")
//        case .password where generatorModeNavData.secretCreationMode == .generate:
//            return String(localized: "generatePasswordSecretInfoSubtitle")
        case .mnemonic where generatorModeNavData.secretCreationMode == .manualImport:
            return String(localized: "importMnemonicSecretInfoSubtitle")
//        case .password where generatorModeNavData.secretCreationMode == .manualImport:
//            return String(localized: "importPasswordSecretInfoSubtitle")
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
                        
                        if generatorModeNavData.generatorMode == .mnemonic && generatorModeNavData.secretCreationMode != .manualImport {
                            SelectableCardInfoBox(mode: .dropdown(self.mnemonicSizeOptions), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { options in
                                showPickerSheet = true
                            }
                        } else if generatorModeNavData.generatorMode == .mnemonic && generatorModeNavData.secretCreationMode == .manualImport {
                            EditableCardInfoBox(mode: .fixedText("Mnemonic"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { options in
                                showPickerSheet = true
                            }
                        }
                        
//                        if generatorModeNavData.generatorMode == .password {
//                            EditableCardInfoBox(mode: .text("Login"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5, shouldDisplaySuggestions: true,
//                                    action:
//                                    { loginTextResult in
//                                        if case .text(let customLoginText) = loginTextResult {
//                                            loginText = customLoginText
//                                        }
//                                    },
//                                    focusAction: {
//                                        withAnimation {
//                                            scrollValue.scrollTo(0, anchor: .top)
//                                        }
//                                    }
//                            )
//                            .id(0)
//                        }
                        
//                        if generatorModeNavData.generatorMode == .password {
//                            Spacer()
//                                .frame(height: 16)
//                            
//                            EditableCardInfoBox(mode: .text("Url"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { urlTextResult in
//                                if case .text(let customUrlText) = urlTextResult {
//                                    urlText = customUrlText
//                                }
//                            }
//                        }
                        
//                        if generatorModeNavData.generatorMode == .password && generatorModeNavData.secretCreationMode != .manualImport {
//                            Spacer()
//                                .frame(height: 16)
//                            
//                            PasswordGeneratorBox(options: passwordOptions)
//                        }
                        
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
                        
                        SKSecretViewer(secretType: .unknown, shouldShowQRCode: .constant(false), contentText: $seedPhrase, isEditable: generatorModeNavData.secretCreationMode == .manualImport) { result in
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
                                
//                                if generatorModeNavData.generatorMode == .password, canManualImportPassword {
//                                    
//                                    cardState.passwordManualImportPayload = PasswordManualImportPayload(label: labelText!,
//                                                                                                        login: loginText,
//                                                                                                        url: urlText,
//                                                                                                        result: seedPhrase)
//                                    
//                                    cardState.requestManualImportSecret(secretType: .password)
//                                }
                            })
                        } else {
                            HStack(alignment: .center, spacing: 0) {
                                Spacer()
                                
                                HStack(alignment: .center, spacing: 12) {
//                                    if generatorModeNavData.generatorMode == .password,
//                                       canGeneratePassword,
//                                       !seedPhrase.isEmpty,
//                                       self.generateBtnMode == .willImport {
//                                        Spacer()
//                                        
//                                        SKImageButton(iconName: "ic_refresh", style: .regular, staticWidth: 56, isEnabled: true, action: {
//                                            seedPhrase = generatePassword(options: passwordOptions)
//                                        })
//                                        .frame(width: 56, alignment: .center)
//                                        
//                                        Spacer()
//                                    }
                                    
                                    SKButton(text: continueBtnTitle, style: .regular, horizontalPadding: 66, isEnabled: canGenerateMnemonic, action: {
                                        if generateBtnMode == .willGenerate {
                                            
                                            if generatorModeNavData.generatorMode == .mnemonic, canGenerateMnemonic {
                                                
                                                seedPhrase = generateMnemonic() ?? "Failed to generate mnemonic"
                                                
                                                mnemonicPayload = MnemonicPayload(label: labelText!,
                                                                                  mnemonicSize: mnemonicSizeOptions.selectedOption!,
                                                                                  passphrase: passphraseText,
                                                                                  result: seedPhrase)
                                            }
                                            
//                                            if generatorModeNavData.generatorMode == .password, canGeneratePassword {
//                                                let password = generatePassword(options: passwordOptions)
//                                                
//                                                seedPhrase = password
//                                                
//                                                passwordPayload = PasswordPayload(label: labelText!,
//                                                                                  login: loginText,
//                                                                                  url: urlText,
//                                                                                  passwordLength: passwordOptions.passwordLength,
//                                                                                  result: seedPhrase)
//                                            }
                                            
                                        } else if generateBtnMode == .willImport {
                                            if let mnemonicPayload = self.mnemonicPayload {
                                                print("will import mnemonic")
                                                cardState.mnemonicPayloadToImportOnCard = mnemonicPayload
                                                cardState.requestAddSecret(secretType: .bip39Mnemonic)
                                            }
                                            
//                                            if let passwordPayload = self.passwordPayload {
//                                                print("will import password")
//                                                cardState.passwordPayloadToImportOnCard = passwordPayload
//                                                cardState.requestAddSecret(secretType: .password)
//                                            }
                                        }
                                    })
                                    .frame(minWidth: 200, alignment: .center)
                                    .frame(maxWidth: .infinity)
                                    .transaction { transaction in
                                        transaction.animation = nil
                                    }
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
//        .onChange(of: self.passwordOptions.passwordLength) { newValue in
//            self.generateBtnMode = .willGenerate
//        }
//        .onChange(of: self.passwordOptions.isMemorablePassword) { newValue in
//            self.generateBtnMode = .willGenerate
//        }
//        .onChange(of: self.passwordOptions.includeLowercase) { newValue in
//            self.generateBtnMode = .willGenerate
//        }
//        .onChange(of: self.passwordOptions.includeNumbers) { newValue in
//            self.generateBtnMode = .willGenerate
//        }
//        .onChange(of: self.passwordOptions.includeSymbols) { newValue in
//            self.generateBtnMode = .willGenerate
//        }
//        .onChange(of: self.passwordOptions.includeUppercase) { newValue in
//            self.generateBtnMode = .willGenerate
//        }
        .onChange(of: self.mnemonicSizeOptions.selectedOption) { newValue in
            self.generateBtnMode = .willGenerate
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
            if #available(iOS 16.4, *) {
                OptionSelectorView(pickerOptions: $mnemonicSizeOptions)
                    .presentationDetents([.height(Dimensions.optionSelectorSheetHeight)])
                    .presentationBackground(.ultraThinMaterial)
            } else {
                OptionSelectorView(pickerOptions: $mnemonicSizeOptions)
                    .presentationDetents([.height(Dimensions.optionSelectorSheetHeight)])
                    .background(Image("bg-glow-small")
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 10)
                        .edgesIgnoringSafeArea(.all))
            }
        }
        .onDisappear {
            cardState.cleanPayloadToImportOnCard()
        }
    }
}


//enum GenerateBtnMode {
//    case willGenerate
//    case willImport
//}

//struct GeneratorModeNavData: Hashable {
//    let generatorMode: GeneratorMode
//    let secretCreationMode: SecretCreationMode
//    
//    init(generatorMode: GeneratorMode, secretCreationMode: SecretCreationMode) {
//        self.generatorMode = generatorMode
//        self.secretCreationMode = secretCreationMode
//    }
//}

//enum GeneratorMode: String, CaseIterable, Hashable, HumanReadable {
//    case mnemonic
//    case password
//    
//    // TODO:  not used?
//    func humanReadableName() -> String {
//        switch self {
//        case .mnemonic:
//            return String(localized: "mnemonicPhrase")
//        case .password:
//            return String(localized: "loginPasswordPhrase")
//        }
//    }
//}

enum MnemonicSize: String, CaseIterable, Hashable, HumanReadable {
    case twelveWords
    case eighteenWords
    case twentyFourWords
    
    // TODO: not used?
    func humanReadableName() -> String {
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

// MARK: Payload types

// TODO: remove?
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
    
    func getSeedQRContent() -> [UInt8]? {
        let result = SKMnemonicEnglish().getCompactSeedQRBitStream(from: self.mnemonic)
        let byteArray = SKMnemonicEnglish().bitstreamToByteArray(bitstream: result)
        return byteArray
    }
    
    func getSeedQRImage() -> UIImage? {
        let wordlist = SKMnemonicEnglish.wordList
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



// SECRET_TYPE_MASTER_SEED (subtype SECRET_SUBTYPE_BIP39): [ masterseed_size(1b) | masterseed | wordlist_selector(1b) | entropy_size(1b) | entropy(<=32b) | passphrase_size(1b) | passphrase] where entropy is 16-32 bytes as defined in BIP39 (this format is backward compatible with SECRET_TYPE_MASTER_SEED)

// TODO: merge MnemonicManualImportPayload & MnemonicPayload
struct MnemonicPayload {
    var label: String
    var mnemonicSize: MnemonicSize
    var passphrase: String?
    var result: String
    
    func getV1PayloadBytes() -> [UInt8] {
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
    
    func getV2PayloadBytes() -> [UInt8] {
        let mnemonicBytes = [UInt8](result.utf8)
        let mnemonicSize = UInt8(mnemonicBytes.count)
        
        var payload: [UInt8] = []
        
        payload.append(mnemonicSize)
        payload.append(contentsOf: mnemonicBytes)
        
        let worldlistSelector: UInt8 = 0x00
        payload.append(worldlistSelector)
        
        do {
            let entropy = try Mnemonic.mnemonicToEntropy(bip39: result)
            let entropySize = UInt8(entropy.count)
            payload.append(entropySize)
            payload.append(contentsOf: entropy)
        } catch {
            print("Error converting mnemonic to entropy: \(error)")
        }
        
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
    
    func getV1PayloadBytes() -> [UInt8] {
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
    
    func getV2PayloadBytes() -> [UInt8] {
        let mnemonicBytes = [UInt8](result.utf8)
        let mnemonicSize = UInt8(mnemonicBytes.count)
        
        var payload: [UInt8] = []
        
        payload.append(mnemonicSize)
        payload.append(contentsOf: mnemonicBytes)
        
        let worldlistSelector: UInt8 = 0x00
        payload.append(worldlistSelector)
        
        do {
            let entropy = try Mnemonic.mnemonicToEntropy(bip39: result)
            let entropySize = UInt8(entropy.count)
            payload.append(entropySize)
            payload.append(contentsOf: entropy)
        } catch {
            print("Error converting mnemonic to entropy: \(error)")
        }
        
        if let passphrase = passphrase {
            let passphraseBytes = [UInt8](passphrase.utf8)
            let passphraseSize = UInt8(passphraseBytes.count)
            payload.append(passphraseSize)
            payload.append(contentsOf: passphraseBytes)
        }

        return payload
    }
}

//struct MasterseedCardData {
//    let blob: String
//}

//struct ElectrumMnemonicCardData {
//    let mnemonic: String
//    let passphrase: String
//    
//    func getSeedQRContent() -> [UInt8]? {
//        let result = SKMnemonicEnglish().getCompactSeedQRBitStream(from: self.mnemonic)
//        let byteArray = SKMnemonicEnglish().bitstreamToByteArray(bitstream: result)
//        return byteArray
//    }
//    
//    func getMnemonicSize() -> MnemonicSize? {
//        let mnemonicWords = mnemonic.split(separator: " ")
//        switch mnemonicWords.count {
//        case 12:
//            return .twelveWords
//        case 18:
//            return .eighteenWords
//        case 24:
//            return .twentyFourWords
//        default:
//            return nil
//        }
//    }
//}

struct MasterseedMnemonicCardData {
    let passphrase: String
    let mnemonic: String
    let size: Int
    let descriptor: String
    
    func getSeedQRContent() -> [UInt8]? {
        let result = SKMnemonicEnglish().getCompactSeedQRBitStream(from: self.mnemonic)
        let byteArray = SKMnemonicEnglish().bitstreamToByteArray(bitstream: result)
        return byteArray
    }
    
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
}

//struct GenericCardData {
//    let blob: String
//}

//struct TwoFACardData {
//    let blob: String
//}

// TODO: remove
//struct PasswordCardData {
//    let password: String
//    let login: String
//    let url: String
//}

// TODO: merge PasswordPayload & PasswordManualImportPayload very similar
//struct PasswordPayload {
//    var label: String
//    var login: String?
//    var url: String?
//    var passwordLength: Double
//    var result: String
//
//    func getPayloadBytes() -> [UInt8] {
//        let passwordBytes = [UInt8](result.utf8)
//        let passwordSize = UInt8(passwordBytes.count)
//
//        var payload: [UInt8] = []
//        payload.append(passwordSize)
//        payload.append(contentsOf: passwordBytes)
//
//        if let login = login {
//            let loginBytes = [UInt8](login.utf8)
//            let loginSize = UInt8(loginBytes.count)
//            payload.append(loginSize)
//            payload.append(contentsOf: loginBytes)
//        }
//
//        if let url = url {
//            let urlBytes = [UInt8](url.utf8)
//            let urlSize = UInt8(urlBytes.count)
//            payload.append(urlSize)
//            payload.append(contentsOf: urlBytes)
//        }
//
//        return payload
//    }
//}

//struct PasswordManualImportPayload {
//    var label: String
//    var login: String?
//    var url: String?
//    var result: String
//
//    func getPayloadBytes() -> [UInt8] {
//        let passwordBytes = [UInt8](result.utf8)
//        let passwordSize = UInt8(passwordBytes.count)
//
//        var payload: [UInt8] = []
//        payload.append(passwordSize)
//        payload.append(contentsOf: passwordBytes)
//
//        if let login = login {
//            let loginBytes = [UInt8](login.utf8)
//            let loginSize = UInt8(loginBytes.count)
//            payload.append(loginSize)
//            payload.append(contentsOf: loginBytes)
//        }
//
//        if let url = url {
//            let urlBytes = [UInt8](url.utf8)
//            let urlSize = UInt8(urlBytes.count)
//            payload.append(urlSize)
//            payload.append(contentsOf: urlBytes)
//        }
//
//        return payload
//    }
//}