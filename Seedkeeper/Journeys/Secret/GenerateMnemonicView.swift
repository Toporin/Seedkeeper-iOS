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
    
    @State private var labelText: String?
    @State private var passphraseText: String?
    @State private var descriptorText: String?
    
    @State private var mnemonicPayload: MnemonicPayload?
    
    @State var seedPhrase = ""
    
    @State var mnemonicSizeOptions = PickerOptions(placeHolder: String(localized: "selectMnemonicSize"), items: MnemonicSize.self)
    
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
    
    func getViewTitle() -> String {
        switch generatorModeNavData.secretCreationMode {
        case .generate:
            return String(localized: "generateMnemonicSecret")
        case .manualImport:
            return String(localized: "importMnemonicSecret")
        }
    }
    
    func getViewSubtitle() -> String {
        switch generatorModeNavData.secretCreationMode {
        case .generate:
            return String(localized: "generateMnemonicSecretInfoSubtitle")
        case .manualImport:
            return String(localized: "importMnemonicSecretInfoSubtitle")
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
                        
                        if generatorModeNavData.secretCreationMode != .manualImport {
                            SelectableCardInfoBox(mode: .dropdown(self.mnemonicSizeOptions), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { options in
                                showPickerSheet = true
                            }
                        } else if generatorModeNavData.secretCreationMode == .manualImport {
                            // TODO: remove?
                            EditableCardInfoBox(mode: .fixedText("Mnemonic"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { options in
                                showPickerSheet = true
                            }
                        }
                            
                        Spacer()
                            .frame(height: 16)
                        
                        EditableCardInfoBox(mode: .text("Passphrase"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { passphraseTextResult in
                            if case .text(let customPassphraseText) = passphraseTextResult {
                                passphraseText = customPassphraseText
                            }
                        }
                        
                        Spacer()
                            .frame(height: 16)
                        
                        EditableCardInfoBox(mode: .text("Wallet descriptor"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { descriptorTextResult in
                            if case .text(let customDescriptorText) = descriptorTextResult {
                                descriptorText = customDescriptorText
                            }
                        }
                            
                        Spacer()
                            .frame(height: 60)
                        
                        SKSecretViewer(secretType: .unknown, shouldShowQRCode: .constant(false), contentText: $seedPhrase, isEditable: generatorModeNavData.secretCreationMode == .manualImport) { result in
                        }

                        Spacer()
                            .frame(height: 16)
                        
                        if generatorModeNavData.secretCreationMode == .manualImport {
                            SKButton(text: String(localized: "import"), style: .regular, horizontalPadding: 66, isEnabled: canManualImportMnemonic, action: {
                                var payload = MnemonicPayload(label: labelText!,
                                                              mnemonic: seedPhrase,
                                                              passphrase: passphraseText,
                                                              descriptor: descriptorText)
                                cardState.requestImportSecret(secretPayload: payload, onSuccess: {}, onFail: {})
                            })
                        } else {
                            HStack(alignment: .center, spacing: 0) {
                                Spacer()
                                
                                HStack(alignment: .center, spacing: 12) {
                                    
                                    // generate button
                                    SKButton(text: String(localized: "generate"), style: .regular, horizontalPadding: 20, isEnabled: canGenerateMnemonic, action: {
                                                seedPhrase = generateMnemonic() ?? "Failed to generate mnemonic"
                                                mnemonicPayload = MnemonicPayload(label: labelText!,
                                                                                  mnemonic: seedPhrase,
                                                                                  passphrase: passphraseText,
                                                                                  descriptor: descriptorText)
                                    })
                                    
                                    // import button
                                    SKButton(text: String(localized: "import"), style: .regular, horizontalPadding: 20, isEnabled: canManualImportMnemonic, action: {
                                            if let mnemonicPayload = self.mnemonicPayload {
                                                print("will import mnemonic")
                                                cardState.requestImportSecret(secretPayload: mnemonicPayload, onSuccess: {}, onFail: {})
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
    }
}

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

// SECRET_TYPE_MASTER_SEED (subtype SECRET_SUBTYPE_BIP39): [ masterseed_size(1b) | masterseed | wordlist_selector(1b) | entropy_size(1b) | entropy(<=32b) | passphrase_size(1b) | passphrase] where entropy is 16-32 bytes as defined in BIP39 (this format is backward compatible with SECRET_TYPE_MASTER_SEED)
struct MnemonicPayload : Payload {
    var label: String
    var mnemonic: String
    var passphrase: String?
    var descriptor: String?
    
    var type = SeedkeeperSecretType.masterseed
    var subtype = UInt8(0x01)
    
    func getPayloadBytes() -> [UInt8] { // getV2PayloadBytes
        let mnemonicBytes = [UInt8](mnemonic.utf8)
        let mnemonicSize = UInt8(mnemonicBytes.count)
        
        var payload: [UInt8] = []
        
        payload.append(mnemonicSize)
        payload.append(contentsOf: mnemonicBytes)
        
        let worldlistSelector: UInt8 = 0x00
        payload.append(worldlistSelector)
        
        do {
            let entropy = try Mnemonic.mnemonicToEntropy(bip39: mnemonic)
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
        
        // add descriptor
        if let descriptor = descriptor {
            let descriptorBytes = [UInt8](descriptor.utf8)
            let descriptorSize = [UInt8((descriptorBytes.count>>8)%256), UInt8(descriptorBytes.count%256)]
            payload.append(contentsOf: descriptorSize)
            payload.append(contentsOf: descriptorBytes)
        }
        print("Debug getV2PayloadBytes: \(payload.bytesToHex)")
        return payload
    }
    
    func getFingerprintBytes() -> [UInt8] {
        return SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: getPayloadBytes())
    }
    
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
