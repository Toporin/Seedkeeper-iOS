//
//  Payload.swift
//  Seedkeeper
//
//  Created by Satochip on 16/09/2024.
//

import SatochipSwift

protocol Payload: HumanReadable {
    var label: String { get set }
    var type: SeedkeeperSecretType {get set}
    var subtype: UInt8 {get set}
    
    func getPayloadBytes() -> [UInt8]
    func getContentString() -> String
}


// MARK: Payload types
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
    
    func getContentString() -> String {
        return masterseedBytes.bytesToHex
    }
    
    func humanReadableName() -> String {
        return "Masterseed";
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
    
    func getContentString() -> String {
        return mnemonic
    }
    
    func humanReadableName() -> String {
        return "Electrum seed";
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
    
    func getContentString() -> String {
        return mnemonic
    }
    
    func humanReadableName() -> String {
        return "Bip39 seed";
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

struct PubkeyPayload : Payload {
    var label: String
    var pubkeyBytes: [UInt8]
    
    var type = SeedkeeperSecretType.pubkey
    var subtype = UInt8(0x00)
    
    func getPayloadBytes() -> [UInt8] {
        
        let pubkeySize = UInt8(pubkeyBytes.count)
        
        var payload: [UInt8] = []
        payload.append(pubkeySize)
        payload.append(contentsOf: pubkeyBytes)
        
        return payload
    }
    
    func getContentString() -> String {
        return pubkeyBytes.bytesToHex
    }
    
    func humanReadableName() -> String {
        return "Pubkey";
    }
}

struct Secret2FAPayload : Payload {
    var label: String
    var secretBytes: [UInt8]
    
    var type = SeedkeeperSecretType.secret2FA
    var subtype = UInt8(0x00)
    
    func getPayloadBytes() -> [UInt8] {
        
        let secretSize = UInt8(secretBytes.count)
        
        var payload: [UInt8] = []
        payload.append(secretSize)
        payload.append(contentsOf: secretBytes)
        
        return payload
    }
    
    func getContentString() -> String {
        return secretBytes.bytesToHex
    }
    
    func humanReadableName() -> String {
        return "2FA secret";
    }
}

struct DefaultPayload : Payload {
    var label: String
    var defaultBytes: [UInt8]
    
    var type = SeedkeeperSecretType.defaultType
    var subtype = UInt8(0x00)
    
    func getPayloadBytes() -> [UInt8] {
        
        let defaultSize = UInt8(defaultBytes.count)
        
        var payload: [UInt8] = []
        payload.append(defaultSize)
        payload.append(contentsOf: defaultBytes)
        
        return payload
    }
    
    func getContentString() -> String {
        return defaultBytes.bytesToHex
    }
    
    func humanReadableName() -> String {
        return "Secret";
    }
}


// MARK: Parsing to payload
func parseBytesToPayload(secretType: SeedkeeperSecretType, secretSubtype: UInt8, bytes: [UInt8]) -> Payload? {
    
    switch secretType {
    case .password:
        return parseToPasswordPayload(bytes: bytes)
    case .defaultType:
        return parseToDefaultPayload(bytes: bytes)
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
        return parseToDefaultPayload(bytes: bytes) // TODO: implement specific parser
    case .privkey:
        return parseToDefaultPayload(bytes: bytes) // TODO: implement specific parser
    case .pubkey:
        return parseToPubkeyPayload(bytes: bytes)
    case .pubkeyAuthenticated:
        return parseToDefaultPayload(bytes: bytes) // TODO: implement specific parser
    case .key:
        return parseToDefaultPayload(bytes: bytes) // TODO: implement specific parser
    case .masterPassword:
        return parseToDefaultPayload(bytes: bytes) // TODO: implement specific parser
    case .certificate:
        return parseToDefaultPayload(bytes: bytes) // TODO: implement specific parser
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

    return PasswordPayload(label:"", password: password, login: login, url: url)
}

// MARK: MasterseedMnemonicPayload
func parseToMasterseedMnemonicPayload(bytes: [UInt8]) -> MnemonicPayload? {
    let logger = LoggerService.shared
    logger.info("START parsing secret to MasterseedMnemonic", tag: "parseToMasterseedMnemonicPayload")
    
    var index = 0
    // Check index before accessing bytes
    guard index < bytes.count else {
        logger.error("Index out of bounds when reading masterseedSize", tag: "parseToMasterseedMnemonicPayload")
        return nil
    }
    
    // Extract masterseed size and masterseed
    let masterseedSize = Int(bytes[index])
    index += 1
    guard index + masterseedSize <= bytes.count else {
        logger.error("Invalid masterseed size: \(masterseedSize)", tag: "parseToMasterseedMnemonicPayload")
        return nil
    }
    let masterseedBytes = Array(bytes[index..<(index + masterseedSize)])
    index += masterseedSize
    
    // get wordlist selector
    guard index <= bytes.count else {
        logger.error("Index out of bounds when reading wordlistSelector", tag: "parseToMasterseedMnemonicPayload")
        return nil
    }
    let wordlistSelector = Int(bytes[index]) // TODO: use selector
    index += 1
    
    // Extract entropy if available
    guard index <= bytes.count else {
        logger.error("Index out of bounds when reading entropySize", tag: "parseToMasterseedMnemonicPayload")
        return nil
    }
    let entropySize = Int(bytes[index])
    index += 1
    guard index + entropySize <= bytes.count else {
        logger.error("Index out of bounds when reading entropy", tag: "parseToMasterseedMnemonicPayload")
        return nil
    }
    let entropyBytes = Array(bytes[index..<(index + entropySize)])
    index += entropySize
    
    // convert entropy to mnemonic
    var mnemonic = ""
    do {
        mnemonic = try Mnemonic.entropyToMnemonic(entropy: entropyBytes)
    } catch let error {
        logger.error("Failed to convert entropy to mnemonic: \(error)", tag: "parseToMasterseedMnemonicPayload")
        mnemonic = "Failed to recover mnemonic from entropy: \(entropyBytes.bytesToHex)"
    }
    
    // Extract passphrase size and passphrase if available
    var passphrase: String? = nil
    if index < bytes.count {
        let passphraseSize = Int(bytes[index])
        index += 1
        if passphraseSize > 0 && index + passphraseSize <= bytes.count {
            logger.info("Found passphrase with size: \(passphraseSize) ", tag: "parseToMasterseedMnemonicPayload")
            let passphraseBytes = Array(bytes[index..<(index + passphraseSize)])
            index += passphraseSize
            passphrase = String(bytes: passphraseBytes, encoding: .utf8)
        } else {
            logger.info("Wrong passphrase size: \(passphraseSize) ", tag: "parseToMasterseedMnemonicPayload")
        }
    }
    
    // Extract descriptor size and descriptor if available
    var descriptor: String? = nil
    if index < (bytes.count-1) {
        let descriptorSize = Int(bytes[index])*256 + Int(bytes[index+1])
        index += 2
        if descriptorSize > 0 && (index + descriptorSize) <= bytes.count {
            logger.info("Found descriptor with size: \(descriptorSize) ", tag: "parseToMasterseedMnemonicPayload")
            let descriptorBytes = Array(bytes[index..<(index + descriptorSize)])
            index += descriptorSize
            descriptor = String(bytes: descriptorBytes, encoding: .utf8)
        } else {
            logger.info("Wrong descriptor size: \(descriptorSize) ", tag: "parseToMasterseedMnemonicPayload")
        }
    }
    logger.info("END parsing secret to MasterseedMnemonic", tag: "parseToMasterseedMnemonicPayload")
    
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
    
    var data = String(bytes: dataBytes, encoding: .utf8)
    if data == nil {
        print("Failed to convert dataBytes to string")
        data = dataBytes.bytesToHex //convert to hexstring instead
    }
    
    return DataPayload(label: "", data: data ?? "Failed to parse data secret")
}

func parseToPubkeyPayload(bytes: [UInt8]) -> PubkeyPayload? {
    var index = 0

    let pubkeySize = Int(bytes[index])
    index += 1
    
    guard index + pubkeySize <= bytes.count else {
        print("Invalid blob size")
        return nil
    }
    
    let pubkeyBytes = Array(bytes[index..<(index + pubkeySize)])
        
    return PubkeyPayload(label: "", pubkeyBytes: pubkeyBytes)
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
        
    return Secret2FAPayload(label: "", secretBytes: secret2FABytes)
}

func parseToDefaultPayload(bytes: [UInt8]) -> DefaultPayload? {
    var index = 0

    let defaultSize = Int(bytes[index])
    index += 1
    
    guard index + defaultSize <= bytes.count else {
        print("Invalid blob size")
        return nil
    }
    
    let defaultBytes = Array(bytes[index..<(index + defaultSize)])
       
    return DefaultPayload(label: "", defaultBytes: defaultBytes)
}
