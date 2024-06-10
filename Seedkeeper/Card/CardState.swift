//
//  CardData.swift
//  Satodime
//
//  Created by Satochip on 01/12/2023.
//

import Foundation
import CoreNFC
import SatochipSwift
import CryptoSwift
import Combine
import SwiftUI

enum SatocardError: Error {
    case testError(String)
    case randomGeneratorError
    case invalidResponse
}

class CardState: ObservableObject {
    var cmdSet: SatocardCommandSet!
    @Published var cardStatus: CardStatus?
    @Published var isCardDataAvailable = false
    @Published var authentikeyHex = ""
    @Published var certificateDic = [String: String]()
    @Published var certificateCode = PkiReturnCode.unknown
    @Published var errorMessage: String?
    @Published var homeNavigationPath = NavigationPath()
    
    var session: SatocardController?
    var cardController: SatocardController?
    
    private(set) var isPinVerificationSuccess: Bool = false
    
    var pinCodeToSetup: String?
    var pinForMasterCard: String?
    
    @Published var masterSecretHeaders: [SeedkeeperSecretHeaderDto] = []
    
    var currentSecretHeader: SeedkeeperSecretHeaderDto?
    @Published var currentSecretObject: SeedkeeperSecretObject? {
        didSet {
            if let secretBytes = currentSecretObject?.secretBytes {
                let secretString = String(bytes: secretBytes, encoding: .utf8)
                currentSecretString = secretString ?? ""
            }
        }
    }
    @Published var currentSecretString: String = ""
    
    // var secretTypeToImportOnCard: SeedkeeperSecretType?
    var passwordPayloadToImportOnCard: PasswordPayload?
    var mnemonicPayloadToImportOnCard: MnemonicPayload?
    
    func cleanShowSecret() {
        currentSecretHeader = nil
        currentSecretObject = nil
        currentSecretString = ""
    }
    
    func cleanPayloadToImportOnCard() {
        // secretTypeToImportOnCard = nil
        passwordPayloadToImportOnCard = nil
        mnemonicPayloadToImportOnCard = nil
    }
    
    func scan() {
        print("CardState scan()")
        DispatchQueue.main.async {
            self.resetState()
        }
        session = SatocardController(onConnect: onConnection, onFailure: onDisconnection)
        session?.start(alertMessage: "Scan your card")
    }
    
    private func resetState() {
        certificateCode = .unknown
        authentikeyHex = ""
        isCardDataAvailable = false
    }
    
    // Card connection
    func onConnection(cardChannel: CardChannel) -> Void {
        Task {
            do {
                try await handleConnection(cardChannel: cardChannel)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)"
                }
                session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
            }
        }
    }
    
    private func setCardStatus(statusApdu: APDUResponse, completion: @escaping () -> Void){
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.cardStatus = try? CardStatus(rapdu: statusApdu)
            completion()
        }
        
    }
    
    func getCardLabel() -> String {
        return "n/a"
    }
    
    // Delete secret
    
    func requestDeleteSecret() {
        session = SatocardController(onConnect: onDeleteSecret, onFailure: onDisconnection)
        session?.start(alertMessage: "Scan your card")
    }
    
    private func onDeleteSecret(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = pinForMasterCard,
              let currentSecretHeader = self.currentSecretHeader else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            var rapdu = try cmdSet.seedkeeperResetSecret(sid: currentSecretHeader.sid)
            try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
            homeNavigationPath.removeLast()
            session?.stop(alertMessage: "Secret deleted")
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    // Get Xpub
    
    func requestGetXpub() {
        session = SatocardController(onConnect: onGetXpub, onFailure: onDisconnection)
        session?.start(alertMessage: "Scan your card")
    }
    
    private func onGetXpub(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = pinForMasterCard,
              let currentSecretHeader = self.currentSecretHeader else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            let paths = [ "m/0/0/0"]
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            let xpub = try cmdSet.cardBip32GetXpub(path: "m/0/0/0", xtype: XPUB_HEADERS_MAINNET.standard.rawValue, sid: currentSecretHeader.sid)
            currentSecretString = xpub
            session?.stop(alertMessage: "nfcXpubFetchSuccess")
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    // Add secret
    
    func requestAddSecret(secretType: SeedkeeperSecretType) {
        // secretTypeToImportOnCard = secretType
        switch secretType {
        case .bip39Mnemonic:
            session = SatocardController(onConnect: onAddMnemonicSecret, onFailure: onDisconnection)
            session?.start(alertMessage: "Scan your card")
        case .password:
            session = SatocardController(onConnect: onAddPasswordSecret, onFailure: onDisconnection)
            session?.start(alertMessage: "Scan your card")
        default:
            print("requestAddSecret : No action defined for \(secretType.rawValue)")
        }
    }
    
    private func onAddMnemonicSecret(cardChannel: CardChannel) -> Void {
        print("onAddMnemonicSecret")
        guard let pinForMasterCard = pinForMasterCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            // homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
            return
        }
        
        guard let mnemonicPayload = mnemonicPayloadToImportOnCard else {
            session?.stop(errorMessage: String(localized: "nfcPasswordPayloadIsNotDefined"))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
            let secretBytes = [UInt8(Array(mnemonicPayload.result.utf8).count)] + Array(mnemonicPayload.result.utf8)
            let secretFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: secretBytes)
            
            let label = mnemonicPayload.label
            
            let secretHeader = SeedkeeperSecretHeader(type: SeedkeeperSecretType.bip39Mnemonic,
                                                      subtype: UInt8(0x00),
                                                      fingerprintBytes: secretFingerprintBytes,
                                                      label: label)
            let secretObject = SeedkeeperSecretObject(secretBytes: secretBytes,
                                                      secretHeader: secretHeader,
                                                      isEncrypted: false)
            
            let (rapdu, sid, fingerprintBytes) = try cmdSet.seedkeeperImportSecret(secretObject: secretObject)
            
            try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
            
            try checkEqual(fingerprintBytes, secretFingerprintBytes, tag: "Function: \(#function), line: \(#line)")
                        
            homeNavigationPath.append(NavigationRoutes.generateSuccess(label))
            
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
        
        session?.stop(alertMessage: String(localized: "nfcSecretAdded"))
    }
    
    private func onAddPasswordSecret(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = pinForMasterCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            return
        }
        
        guard let passwordPayload = passwordPayloadToImportOnCard else {
            session?.stop(errorMessage: String(localized: "nfcPasswordPayloadIsNotDefined"))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
            let secretBytes = [UInt8(Array(passwordPayload.result.utf8).count)] + Array(passwordPayload.result.utf8)
            let secretFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: secretBytes)
            
            let label = passwordPayload.label
            
            let secretHeader = SeedkeeperSecretHeader(type: SeedkeeperSecretType.password,
                                                      subtype: UInt8(0x00),
                                                      fingerprintBytes: secretFingerprintBytes,
                                                      label: label)
            let secretObject = SeedkeeperSecretObject(secretBytes: secretBytes,
                                                      secretHeader: secretHeader,
                                                      isEncrypted: false)
            
            let (rapdu, sid, fingerprintBytes) = try cmdSet.seedkeeperImportSecret(secretObject: secretObject)
            
            try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
            
            try checkEqual(fingerprintBytes, secretFingerprintBytes, tag: "Function: \(#function), line: \(#line)")
            
            homeNavigationPath.append(NavigationRoutes.generateSuccess(label))
            
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
        
        session?.stop(alertMessage: String(localized: "nfcSecretAdded"))
    }
    
    // get secret
    
    func requestGetSecret(with secretHeader: SeedkeeperSecretHeaderDto) {
        currentSecretHeader = secretHeader
        session = SatocardController(onConnect: onGetSecret, onFailure: onDisconnection)
        session?.start(alertMessage: "Scan your card")
    }
    
    private func onGetSecret(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = self.pinForMasterCard,
              let currentSecretHeader = self.currentSecretHeader else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            // homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var pinResponse = try cmdSet.cardVerifyPIN(pin: pinBytes)
            var result = try cmdSet.seedkeeperExportSecret(sid: currentSecretHeader.sid)
            self.currentSecretObject = result
            session?.stop(alertMessage: "Secret fetched")
            print("seedkeeperExportSecret : \(result)")
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    // fetch secrets
    
    func requestFetchSecrets() {
        session = SatocardController(onConnect: onFetchSecrets, onFailure: onDisconnection)
        session?.start(alertMessage: "Scan your card")
    }
    
    private func onFetchSecrets(cardChannel: CardChannel) -> Void  {
        guard let pinForMasterCard = pinForMasterCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            // homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        var sids = [Int]()
        var secrets = [SeedkeeperSecretObject]()
        var fingerprints = [String]()
        
        do {
            var pinResponse = try cmdSet.cardVerifyPIN(pin: pinBytes)
            var secrets: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
            self.masterSecretHeaders = secrets.map { SeedkeeperSecretHeaderDto(secretHeader: $0) }
            session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
            print("Secrets: \(secrets)")
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
        // session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
    }
    
    // Pin code
    
    func requestInitPinOnCard() {
        session = SatocardController(onConnect: onSetPinCode, onFailure: onDisconnection)
        session?.start(alertMessage: "Scan your card")
    }
    
    
    private func onSetPinCode(cardChannel: CardChannel) -> Void {
        guard let pin = pinCodeToSetup else {
            session?.stop(alertMessage: String(localized: "nfcPinCodeIsNotDefined"))
            return
        }
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        let pinBytes = Array(pin.utf8)
        var rapdu = APDUResponse(sw1: 0x00, sw2: 0x00, data: [])
        
        do {
            rapdu = try cmdSet.cardSetup(pin_tries0: 5, pin0: pinBytes)
            print("Pin Set")
            session?.stop(alertMessage: String(localized: "nfcPinCodeSetSuccess"))
            homeNavigationPath.append(NavigationRoutes.setupFaceId(pin))
        } catch let error {
            print("Error: \(error)")
            session?.stop(alertMessage: String(localized: "nfcPinCodeSetFailed"))
        }
        
        pinCodeToSetup = nil
    }
    
    private func handleConnection(cardChannel: CardChannel) async throws {
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        let (statusApdu, cardType) = try await fetchCardStatus()

        cardStatus = try CardStatus(rapdu: statusApdu)
        
        if let cardStatus = cardStatus, !cardStatus.setupDone {
            let version = getCardVersionInt(cardStatus: cardStatus)
            if version <= 0x00010001 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    homeNavigationPath.append(NavigationRoutes.createPinCode(PinCodeNavigationData(mode: .createPinCode, pinCode: nil)))
                }
                session?.stop(alertMessage: String(localized: "nfcSatodimeNeedsSetup"))
                return
            }
        } else {
            guard let pinForMasterCard = pinForMasterCard else {
                session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
                }
                return
            }
            
            let pinBytes = Array(pinForMasterCard.utf8)
            do {
                var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
                self.isPinVerificationSuccess = true
            } catch {
                self.pinForMasterCard = nil
                self.isPinVerificationSuccess = false
                self.session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                return
            }
        }
        
        try await verifyCardAuthenticity()
        try await fetchAuthentikey()
        // try cmdSet.cardVerifyPIN(pin: pinBytes)
        
        DispatchQueue.main.async {
            self.isCardDataAvailable = true
        }
                
        do {
            let secrets: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
            self.masterSecretHeaders = secrets.map { SeedkeeperSecretHeaderDto(secretHeader: $0) }
            print("Secrets: \(secrets)")
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
        
        session?.stop(alertMessage: String(localized: "nfcVaultsListSuccess"))
    }
    
    private func fetchCardStatus() async throws -> (APDUResponse, CardType) {
        var statusApdu: APDUResponse?
        var cardType: CardType?
        
        (statusApdu, cardType) = try cmdSet.selectApplet(cardType: .anycard)
        statusApdu = try cmdSet.cardGetStatus()
        
        guard let apdu = statusApdu else {
            throw SatocardError.invalidResponse
        }
        
        return (apdu, cardType!)
    }
    
    private func verifyCardAuthenticity() async throws {
        let (certificateCode, certificateDic) = try cmdSet.cardVerifyAuthenticity()
        DispatchQueue.main.async {
            self.certificateCode = certificateCode
            self.certificateDic = certificateDic
        }
    }
    
    private func fetchAuthentikey() async throws {
        let (_, _, authentikeyHex) = try cmdSet.cardGetAuthentikey()
        DispatchQueue.main.async {
            self.authentikeyHex = authentikeyHex
        }
    }
    
    // On disconnection
    func onDisconnection(error: Error) {
        // Handle disconnection
    }
    
    // Utilities
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
}
