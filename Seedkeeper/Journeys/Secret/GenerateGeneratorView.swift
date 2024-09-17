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
// TODO: move somewhere else

struct MasterseedPayload : Payload {
    var label: String
    var type = SeedkeeperSecretType.masterseed
    var subtype = UInt8(0x00)
    var masterseedBytes: [UInt8]
    
    func getPayloadBytes() -> [UInt8] {
        
        let secretSize = UInt8(masterseedBytes.count)
        
        var payload: [UInt8] = []
        payload.append(secretSize)
        payload.append(contentsOf: masterseedBytes)
        
        return payload
    }
    
    func getFingerprintBytes() -> [UInt8] {
        return SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: getPayloadBytes())
    }
    
    func getContentString() -> String {
        return masterseedBytes.bytesToHex
    }
    
}

struct ElectrumMnemonicPayload : Payload {
    var label: String
    var mnemonic: String
    var passphrase: String?
    
    var type = SeedkeeperSecretType.electrumMnemonic
    var subtype = UInt8(0x00)
    
    func getPayloadBytes() -> [UInt8] {
        
        let mnemonicBytes = [UInt8](mnemonic.utf8)
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
    
    func getFingerprintBytes() -> [UInt8] {
        return SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: getPayloadBytes())
    }
    
    func getContentString() -> String {
        return mnemonic
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

struct Bip39MnemonicPayload : Payload {
    var label: String
    var mnemonic: String
    var passphrase: String?
    
    var type = SeedkeeperSecretType.bip39Mnemonic
    var subtype = UInt8(0x00)
    
    func getPayloadBytes() -> [UInt8] {
        
        let mnemonicBytes = [UInt8](mnemonic.utf8)
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
    
    func getFingerprintBytes() -> [UInt8] {
        return SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: getPayloadBytes())
    }
    
    func getContentString() -> String {
        return mnemonic
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

struct Secret2FAPayload : Payload {
    var label: String
    var type = SeedkeeperSecretType.secret2FA
    var subtype = UInt8(0x00)
    var secretBytes: [UInt8]
    
    func getPayloadBytes() -> [UInt8] {
        
        let secretSize = UInt8(secretBytes.count)
        
        var payload: [UInt8] = []
        payload.append(secretSize)
        payload.append(contentsOf: secretBytes)
        
        return payload
    }
    
    func getFingerprintBytes() -> [UInt8] {
        return SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: getPayloadBytes())
    }
    
    func getContentString() -> String {
        return secretBytes.bytesToHex
    }
}
