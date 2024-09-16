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


struct GenerateGeneratorView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    
    @Binding var homeNavigationPath: NavigationPath
    @State var generatorModeNavData: GeneratorModeNavData
    
    var body: some View {
        
        switch generatorModeNavData.generatorMode {
        case .mnemonic:
            GenerateMnemonicView(homeNavigationPath: $homeNavigationPath, generatorModeNavData: generatorModeNavData)
        case .password:
            GeneratePasswordView(homeNavigationPath: $homeNavigationPath, generatorModeNavData: generatorModeNavData)
        case .descriptor:
            GenerateDescriptorView(homeNavigationPath: $homeNavigationPath, generatorModeNavData: generatorModeNavData)
        case .data:
            GenerateDataView(homeNavigationPath: $homeNavigationPath, generatorModeNavData: generatorModeNavData)
        }
        
        
//        if generatorModeNavData.generatorMode == .mnemonic {
//            
//            GenerateMnemonicView(homeNavigationPath: $homeNavigationPath, generatorModeNavData: generatorModeNavData)
//            
//        } else if generatorModeNavData.generatorMode == .password {
//            
//            GeneratePasswordView(homeNavigationPath: $homeNavigationPath, generatorModeNavData: generatorModeNavData)
//            
//        } else {
//            // TODO: default
//        }
        
    }
}

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

enum GeneratorMode: String, CaseIterable, Hashable, HumanReadable {
    case mnemonic
    case password
    case descriptor
    case data
    
    // TODO:  not used?
    func humanReadableName() -> String {
        switch self {
        case .mnemonic:
            return String(localized: "mnemonicPhrase")
        case .password:
            return String(localized: "loginPasswordPhrase")
        case .descriptor:
            return "descriptor" //String(localized: "loginPasswordPhrase") //TODO: translation
        case .data:
            return "data" //String(localized: "loginPasswordPhrase") //TODO: translation
        }
    }
}


// MARK: Payload types

struct MasterseedCardData {
    let blob: String
}

// TODO: BIP39mnemonicPayload
// TODO: merge with MnemonicPayload?
struct ElectrumMnemonicCardData {
    let mnemonic: String
    let passphrase: String
    
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

struct GenericCardData {
    let blob: String
}

struct TwoFACardData {
    let blob: String
}
