//
//  Payload.swift
//  Seedkeeper
//
//  Created by Satochip on 16/09/2024.
//

import SatochipSwift

protocol Payload {
    var label: String { get set }
    var type: SeedkeeperSecretType {get set}
    var subtype: UInt8 {get set}
    
    func getPayloadBytes() -> [UInt8]
    func getFingerprintBytes() -> [UInt8]
    func getContentString() -> String
}

func parseBytesToPayload(secretType: SeedkeeperSecretType, secretSubtype: UInt8, bytes: [UInt8]) -> Payload? {
    
    switch secretType {
    case .password:
        return parseToPasswordPayload(bytes: bytes)
    case .defaultType:
        return nil
    case .masterseed:
        if secretSubtype == 0x00 {
            return parseToMasterseedPayload(bytes: bytes)}
        else if secretSubtype == 0x01 {
            return parseToMasterseedMnemonicPayload(bytes: bytes)
        } else {
            return nil
        }
    case .bip39Mnemonic:
        return parseToBip39MnemonicPayload(bytes: bytes)
    case .electrumMnemonic:
        return parseToElectrumMnemonicPayload(bytes: bytes)
    case .shamirSecretShare:
        return nil
    case .privkey:
        return nil
    case .pubkey:
        return nil //TODO: implement
    case .pubkeyAuthenticated:
        return nil
    case .key:
        return nil
    case .masterPassword:
        return nil
    case .certificate:
        return nil
    case .secret2FA:
        return parseToSecret2FAPayload(bytes: bytes)
    case .data:
        return parseToDataPayload(bytes: bytes)
    case .walletDescriptor:
        return parseToDescriptorPayload(bytes: bytes)
    }
    
}

// MARK: password
func parseToPasswordPayload(bytes: [UInt8]) -> PasswordPayload? {
    var index = 0

    // PASSWORD
    let passwordSize = Int(bytes[index])
    index += 1
    guard index + passwordSize <= bytes.count else {
        print("Invalid password size")
        return nil
    }
    let passwordBytes = Array(bytes[index..<(index + passwordSize)])
    index += passwordSize
    guard let password = String(bytes: passwordBytes, encoding: .utf8) else {
        print("Failed to convert password bytes to string")
        return nil
    }

    // LOGIN
    var login: String? = nil
    if index < bytes.count {
        let loginSize = Int(bytes[index])
        index += 1
        if loginSize > 0 && index + loginSize <= bytes.count {
            let loginBytes = Array(bytes[index..<(index + loginSize)])
            index += loginSize
            login = String(bytes: loginBytes, encoding: .utf8)
        }
    }
    
    // URL
    var url: String? = nil
    if index < bytes.count {
        let urlSize = Int(bytes[index])
        index += 1
        if urlSize > 0 && index + urlSize <= bytes.count {
            let urlBytes = Array(bytes[index..<(index + urlSize)])
            index += urlSize
            url = String(bytes: urlBytes, encoding: .utf8)
        }
    }

    return PasswordPayload(label:"", password: password, login: login ?? "n/a", url: url ?? "n/a")
}

// MARK: MasterseedMnemonicPayload
func parseToMasterseedMnemonicPayload(bytes: [UInt8]) -> MnemonicPayload? {
    
    var index = 0
    // Check index before accessing bytes
    guard index < bytes.count else {
        print("Index out of bounds when reading masterseedSize")
        return nil
    }
    
    // Extract masterseed size and masterseed
    let masterseedSize = Int(bytes[index])
    index += 1
    guard index + masterseedSize <= bytes.count else {
        print("Invalid masterseed size")
        return nil
    }
    let masterseedBytes = Array(bytes[index..<(index + masterseedSize)])
    index += masterseedSize
    
    // get wordlist selector
    guard index <= bytes.count else {
        print("Index out of bounds when reading wordlistSelector")
        return nil
    }
    let wordlistSelector = Int(bytes[index]) // TODO: use selector
    index += 1
    
    // Extract entropy if available
    guard index <= bytes.count else {
        print("Index out of bounds when reading entropySize")
        return nil
    }
    let entropySize = Int(bytes[index])
    index += 1
    guard index + entropySize <= bytes.count else {
        print("Index out of bounds when reading entropy")
        return nil
    }
    let entropyBytes = Array(bytes[index..<(index + entropySize)])
    index += entropySize
    
    // convert entropy to mnemonic
    var mnemonic = "n/a"
    do {
        mnemonic = try Mnemonic.entropyToMnemonic(entropy: entropyBytes)
    } catch {
        print("Failed to convert entropy to mnemonic")
        mnemonic = "Failed to recover mnemonic from entropy: \(entropyBytes.bytesToHex)"
    }
    
    // Extract passphrase size and passphrase if available
    var passphrase: String? = nil
    if index < bytes.count {
        let passphraseSize = Int(bytes[index])
        index += 1
        if passphraseSize > 0 && index + passphraseSize <= bytes.count {
            let passphraseBytes = Array(bytes[index..<(index + passphraseSize)])
            index += passphraseSize
            passphrase = String(bytes: passphraseBytes, encoding: .utf8)
        }
    }
    
    // Extract descriptor size and descriptor if available
    var descriptor: String? = nil
    if index < (bytes.count-1) {
        print("in parseMnemonicCardData: there is a descriptor")
        let descriptorSize = Int(bytes[index])*256 + Int(bytes[index+1])
        print("in parseMnemonicCardData: there is a descriptor with size \(descriptorSize)")
        index += 2
        if descriptorSize > 0 && (index + descriptorSize) <= bytes.count {
            let descriptorBytes = Array(bytes[index..<(index + descriptorSize)])
            print("in parseMnemonicCardData: there is a descriptorBytes \(descriptorBytes.bytesToHex)")
            index += descriptorSize
            descriptor = String(bytes: descriptorBytes, encoding: .utf8)
            print("in parseMnemonicCardData: there is a descriptor \(descriptor)")
        }
    }

    return MnemonicPayload(label: "", mnemonic: mnemonic, passphrase: passphrase, descriptor: descriptor)
}


// MARK: ElectrumMnemonicPayload
func parseToElectrumMnemonicPayload(bytes: [UInt8]) -> ElectrumMnemonicPayload? {
    var index = 0

    // Extract mnemonic size and mnemonic
    let mnemonicSize = Int(bytes[index])
    index += 1
    guard index + mnemonicSize <= bytes.count else {
        print("Invalid mnemonic size")
        return nil
    }
    let mnemonicBytes = Array(bytes[index..<(index + mnemonicSize)])
    index += mnemonicSize
    guard let mnemonic = String(bytes: mnemonicBytes, encoding: .utf8) else {
        print("Failed to convert mnemonic bytes to string")
        return nil
    }

    // Extract passphrase size and passphrase if available
    var passphrase: String? = nil
    if index < bytes.count {
        let passphraseSize = Int(bytes[index])
        index += 1
        if passphraseSize > 0 && index + passphraseSize <= bytes.count {
            let passphraseBytes = Array(bytes[index..<(index + passphraseSize)])
            index += passphraseSize
            passphrase = String(bytes: passphraseBytes, encoding: .utf8)
        }
    }

    return ElectrumMnemonicPayload(label:"", mnemonic: mnemonic, passphrase: passphrase)
}

// MARK: Bip39MnemonicPayload
func parseToBip39MnemonicPayload(bytes: [UInt8]) -> Bip39MnemonicPayload? {
    var index = 0

    // Extract mnemonic size and mnemonic
    let mnemonicSize = Int(bytes[index])
    index += 1
    guard index + mnemonicSize <= bytes.count else {
        print("Invalid mnemonic size")
        return nil
    }
    let mnemonicBytes = Array(bytes[index..<(index + mnemonicSize)])
    index += mnemonicSize
    guard let mnemonic = String(bytes: mnemonicBytes, encoding: .utf8) else {
        print("Failed to convert mnemonic bytes to string")
        return nil
    }

    // Extract passphrase size and passphrase if available
    var passphrase: String? = nil
    if index < bytes.count {
        let passphraseSize = Int(bytes[index])
        index += 1
        if passphraseSize > 0 && index + passphraseSize <= bytes.count {
            let passphraseBytes = Array(bytes[index..<(index + passphraseSize)])
            index += passphraseSize
            passphrase = String(bytes: passphraseBytes, encoding: .utf8)
        }
    }

    return Bip39MnemonicPayload(label:"", mnemonic: mnemonic, passphrase: passphrase)
}

// MARK: MasterseedPayload
func parseToMasterseedPayload(bytes: [UInt8]) -> MasterseedPayload? {
    var index = 0

    if bytes.isEmpty {
        print("No bytes to parse!")
        return nil
    }
    
    let masterseedSize = Int(bytes[index])
    index += 1
    
    guard index + masterseedSize <= bytes.count else {
        print("Invalid blob size")
        return nil
    }
    
    let masterseedBytes = Array(bytes[index..<(index + masterseedSize)])
    
    print("Blob Bytes: \(masterseedBytes.bytesToHex)")
    
    return MasterseedPayload(label: "", masterseedBytes: masterseedBytes)
}

func parseToDescriptorPayload(bytes: [UInt8]) -> DescriptorPayload? {
    var index = 0

    let dataSize = Int(bytes[index])*256 + Int(bytes[index+1])
    index += 2
    
    guard index + dataSize <= bytes.count else {
        print("Invalid blob size")
        return nil
    }
    
    let dataBytes = Array(bytes[index..<(index + dataSize)])
    print("Blob Bytes: \(dataBytes.bytesToHex)")
    
    guard let data = String(bytes: dataBytes, encoding: .utf8) else {
        print("Failed to convert dataBytes to string")
        return nil
    }
    
    return DescriptorPayload(label: "", descriptor: data)
}

func parseToDataPayload(bytes: [UInt8]) -> DataPayload? {
    var index = 0

    let dataSize = Int(bytes[index])*256 + Int(bytes[index+1])
    index += 2
    
    guard index + dataSize <= bytes.count else {
        print("Invalid blob size")
        return nil
    }
    
    let dataBytes = Array(bytes[index..<(index + dataSize)])
    print("Blob Bytes: \(dataBytes.bytesToHex)")
    
    guard let data = String(bytes: dataBytes, encoding: .utf8) else {
        print("Failed to convert dataBytes to string")
        return nil // TODO: convert to hexstring instead
    }
    
    return DataPayload(label: "", data: data)
}

func parseToSecret2FAPayload(bytes: [UInt8]) -> Secret2FAPayload? {
    var index = 0

    let secret2FASize = Int(bytes[index])
    index += 1
    
    guard index + secret2FASize <= bytes.count else {
        print("Invalid blob size")
        return nil
    }
    
    let secret2FABytes = Array(bytes[index..<(index + secret2FASize)])
    
    print("Blob Bytes: \(secret2FABytes.bytesToHex)")
    
    return Secret2FAPayload(label: "", secretBytes: secret2FABytes)
}


