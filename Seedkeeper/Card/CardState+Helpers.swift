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
    }
    
    func cleanPayloadToImportOnCard() {
        passwordPayloadToImportOnCard = nil
        mnemonicPayloadToImportOnCard = nil
        
        mnemonicManualImportPayload = nil
        passwordManualImportPayload = nil
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
    
    internal func fetchAuthentikey(cardType: ScannedCardType) async throws {
        let (_, _, authentikeyHex) = try cmdSet.cardGetAuthentikey()
        DispatchQueue.main.async {
            switch cardType {
            case .master:
                self.authentikeyHex = authentikeyHex
            case .backup:
                self.authentikeyHexForBackup = authentikeyHex
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
    
    func parsePasswordCardData(from bytes: [UInt8]) -> PasswordCardData? {
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

        return PasswordCardData(password: password, login: login ?? "n/a", url: url ?? "n/a")
    }

    func parseMnemonicCardData(from bytes: [UInt8]) -> MnemonicCardData? {
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

        return MnemonicCardData(mnemonic: mnemonic, passphrase: passphrase)
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
}
