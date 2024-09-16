//
//  CardState+Helpers.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/06/2024.
//

import Foundation
import CoreNFC
import SatochipSwift
import CryptoSwift
import Combine
import SwiftUI
import MnemonicSwift

extension CardState {
    // *********************************************************
    // MARK: - Helpers
    // *********************************************************
    func cleanShowSecret() {
        currentSecretHeader = nil
        currentSecretObject = nil
        currentPasswordCardData = nil
        currentMnemonicCardData = nil
        currentMasterseedMnemonicCardData = nil
        currentMasterseedCardData = nil
        currentElectrumMnemonicCardData = nil
        currentGenericCardData = nil
    }
    
    internal func resetState() {
        certificateCode = .unknown
        authentikeyHex = ""
        isCardDataAvailable = false
        
        masterSecretHeaders = []
    }
    
    internal func popToBackupFlow() {
        if homeNavigationPath.count >= 2 {
            homeNavigationPath.removeLast(2)
        }
    }
    
    internal func setCardStatus(statusApdu: APDUResponse, completion: @escaping () -> Void){
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.cardStatus = try? CardStatus(rapdu: statusApdu)
            completion()
        }
    }
    
    internal func fetchCardStatus() async throws -> (APDUResponse, CardType) {
        var statusApdu: APDUResponse?
        var cardType: CardType?
        
        // TODO: for v2, status is already provided in select response
        (statusApdu, cardType) = try cmdSet.selectApplet(cardType: .seedkeeper)
        
        statusApdu = try cmdSet.cardGetStatus()
        
        guard let apdu = statusApdu else {
            throw SatocardError.invalidResponse
        }
        
        return (apdu, cardType!)
    }
    
    internal func verifyCardAuthenticity(cardType: ScannedCardType) async throws {
        let (certificateCode, certificateDic) = try cmdSet.cardVerifyAuthenticity()
        DispatchQueue.main.async {
            switch cardType {
            case .master:
                self.certificateCode = certificateCode
                self.certificateDic = certificateDic
            case .backup:
                self.certificateCodeForBackup = certificateCode
                self.certificateDicForBackup = certificateDic
            }
        }
    }
    
    func getReasonFromPkiReturnCode(pkiReturnCode: PkiReturnCode) -> String {
        switch(pkiReturnCode) {
        case PkiReturnCode.FailedToVerifyDeviceCertificate:
            return "_reason_wrong_sig"
        case PkiReturnCode.FailedChallengeResponse:
            return "_reason_wrong_challenge"
        case PkiReturnCode.unknown:
            return "_reason_unknown"
        default:
            return "Reason: \(pkiReturnCode)"
        }
    }
    
    internal func fetchAuthentikey(cardType: ScannedCardType) async throws {
        let (_, authentikeyBytes, authentikeyHex) = try cmdSet.cardGetAuthentikey()
        DispatchQueue.main.async {
            switch cardType {
            case .master:
                self.authentikeyHex = authentikeyHex
                self.authentikeyBytes = authentikeyBytes
            case .backup:
                self.authentikeyHexForBackup = authentikeyHex
                self.authentikeyBytesForBackup = authentikeyBytes
            }
        }
    }
    
    internal func getAuthentikeyHexSilently() async throws -> String {
        let (_, _, authentikeyHex) = try cmdSet.cardGetAuthentikey()
        return authentikeyHex
    }
    
    internal func isAuthentikeyValid(for cardType: ScannedCardType) throws -> Bool {
        let (_, _, authentikeyHex) = try cmdSet.cardGetAuthentikey()
        switch cardType {
        case .master:
            return self.authentikeyHex == authentikeyHex
        case .backup:
            return self.authentikeyHexForBackup == authentikeyHex
        }
    }
    
    func getCardVersionInt(cardStatus: CardStatus) -> Int {
        return Int(cardStatus.protocolMajorVersion) * (1<<24) +
               Int(cardStatus.protocolMinorVersion) * (1<<16) +
               Int(cardStatus.appletMajorVersion) * (1<<8) +
               Int(cardStatus.appletMinorVersion)
    }
    
    public func checkEqual<T: Equatable>(_ lhs: T, _ rhs: T, tag: String) throws {
        // let log = LoggerService.shared
        if (lhs != rhs){
            let msg = "CheckEqual failed: got \(lhs) but expected \(rhs) in \(tag)"
            // log.error(msg, tag: tag)
            throw SatocardError.testError("[\(tag)] \(msg)")
        }
        else {
            // log.debug("CheckEqual ok for: \(lhs)", tag: tag)
        }
    }
    
    // *********************************************************
    // MARK: - Secret parsers
    // *********************************************************
    
    // todo: merge with parseMnemonicCardData
    func parseElectreumMnemonicCardData(bytes: [UInt8]) -> ElectrumMnemonicCardData? {
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

        return ElectrumMnemonicCardData(mnemonic: mnemonic, passphrase: passphrase ?? "n/a")
    }
    
    func parseMasterseedCardData(bytes: [UInt8]) -> MasterseedCardData? {
        var index = 0

        if bytes.isEmpty {
            print("No bytes to parse!")
            return nil
        }
        
        let blobSize = Int(bytes[index])
        index += 1
        
        guard index + blobSize <= bytes.count else {
            print("Invalid blob size")
            return nil
        }
        
        let blobBytes = Array(bytes[index..<(index + blobSize)])
        
        print("Blob Bytes: \(blobBytes)")
        
        let hexString = blobBytes.map { String(format: "%02x", $0) }.joined()
        print("Hexadecimal representation of the bytes: \(hexString)")
        
        return MasterseedCardData(blob: hexString)
    }
    
    func parseMasterseedMnemonicCardData(bytes: [UInt8]) -> MnemonicPayload? {
        
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
    
    // Parse mnemonic in legacy format [mnemonic_size mnemonic passphrase_size passphrase]
    func parseMnemonicCardData(bytes: [UInt8]) -> MnemonicPayload? { //MnemonicCardData? {
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
        
        return MnemonicPayload(label: "", mnemonic: mnemonic, passphrase: passphrase, descriptor: nil)
    }

    func parseGenericCardData(from bytes: [UInt8]) -> GenericCardData? {
        var index = 0

        let blobSize = Int(bytes[index])
        index += 1
        
        guard index + blobSize <= bytes.count else {
            print("Invalid blob size")
            return nil
        }
        
        let blobBytes = Array(bytes[index..<(index + blobSize)])
        
        print("Blob Bytes: \(blobBytes)")
        
        let hexString = blobBytes.map { String(format: "%02x", $0) }.joined()
        print("Hexadecimal representation of the bytes: \(hexString)")
        
        return GenericCardData(blob: hexString)
    }
    
    func parse2FACardData(from bytes: [UInt8]) -> TwoFACardData? {
        var index = 0

        let blobSize = Int(bytes[index])
        index += 1
        
        guard index + blobSize <= bytes.count else {
            print("Invalid blob size")
            return nil
        }
        
        let blobBytes = Array(bytes[index..<(index + blobSize)])
        
        print("Blob Bytes: \(blobBytes)")
        
        let hexString = blobBytes.map { String(format: "%02x", $0) }.joined()
        print("Hexadecimal representation of the bytes: \(hexString)")
        
        return TwoFACardData(blob: hexString)
    }
    
    func parsePasswordCardData(from bytes: [UInt8]) -> PasswordPayload? {
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

}
