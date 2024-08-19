//
//  CardState+Secrets.swift
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
    // MARK: - Set card label
    // *********************************************************
    func requestSetCardLabel(label: String) {
        self.cardLabelToSet = label
        session = SatocardController(onConnect: onSetCardLabel, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    func onSetCardLabel(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = pinForMasterCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
            return
        }
        
        guard let cardLabelToSet = cardLabelToSet else {
            session?.stop(errorMessage: String(localized: "nfcCardLabelIsNotDefined"))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            var rapdu = try cmdSet.cardSetLabel(label: cardLabelToSet)
            if rapdu {
                self.cardLabel = cardLabelToSet
                self.cardLabelToSet = nil
            }
            session?.stop(alertMessage: String(localized: "nfcLabelSetSuccess"))
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    // *********************************************************
    // MARK: - Manual import secret
    // *********************************************************
    func requestManualImportSecret(secretType: SeedkeeperSecretType) {
        switch secretType {
        case .bip39Mnemonic:
            session = SatocardController(onConnect: onManualImportMnemonicSecret, onFailure: onDisconnection)
            session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
        case .password:
            session = SatocardController(onConnect: onManualImportPasswordSecret, onFailure: onDisconnection)
            session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
        default:
            print("requestAddSecret : No action defined for \(secretType.rawValue)")
        }
    }
    
    // SECRET_TYPE_PASSWORD (subtype 0x01): [password_size(1b) | password | login_size(1b) | login | url_size(1b) | url]
    private func onManualImportPasswordSecret(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = pinForMasterCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
            return
        }
        
        guard let passwordPayload = passwordManualImportPayload else {
            session?.stop(errorMessage: String(localized: "nfcPasswordPayloadIsNotDefined"))
            logEvent(log: LogModel(type: .error, message: "onManualImportPasswordSecret : passwordPayload is not defined"))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
            let secretBytes = passwordPayload.getPayloadBytes()
            let secretFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: secretBytes)
            
            let label = passwordPayload.label
            
            let secretHeader = SeedkeeperSecretHeader(type: SeedkeeperSecretType.password,
                                                      subtype: UInt8(0x01),
                                                      fingerprintBytes: secretFingerprintBytes,
                                                      label: label)
            let secretObject = SeedkeeperSecretObject(secretBytes: secretBytes,
                                                      secretHeader: secretHeader,
                                                      isEncrypted: false)
            
            let (rapdu, sid, fingerprintBytes) = try cmdSet.seedkeeperImportSecret(secretObject: secretObject)
            
            try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
            
            try checkEqual(fingerprintBytes, secretFingerprintBytes, tag: "Function: \(#function), line: \(#line)")
            
            self.addSecretToMasterList(secretHeader: SeedkeeperSecretHeaderDto(secretHeader: secretHeader))
            
            homeNavigationPath.append(NavigationRoutes.generateSuccess(label))
            
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
            logEvent(log: LogModel(type: .error, message: "onManualImportPasswordSecret : \(error.localizedDescription)"))
        }
        
        session?.stop(alertMessage: String(localized: "nfcSecretAdded"))
    }
    
    // trigger hidden before fringe cattle height rug blush pause erode shift absent
    // SECRET_TYPE_BIP39_MNEMONIC: [mnemonic_size(1b) | mnemonic | passphrase_size(1b) | passphrase ]
    private func onManualImportMnemonicSecret(cardChannel: CardChannel) -> Void {
        print("onAddMnemonicSecret")
        guard let pinForMasterCard = pinForMasterCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            // homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
            return
        }
        
        guard let mnemonicPayload = mnemonicManualImportPayload else {
            session?.stop(errorMessage: String(localized: "nfcPasswordPayloadIsNotDefined"))
            logEvent(log: LogModel(type: .error, message: "onManualImportMnemonicSecret : mnemonicPayload is not defined"))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
            let secretBytes = mnemonicPayload.getPayloadBytes()
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
            
            self.addSecretToMasterList(secretHeader: SeedkeeperSecretHeaderDto(secretHeader: secretHeader))
                        
            homeNavigationPath.append(NavigationRoutes.generateSuccess(label))
            
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
            logEvent(log: LogModel(type: .error, message: "onManualImportMnemonicSecret : \(error.localizedDescription)"))
        }
        
        session?.stop(alertMessage: String(localized: "nfcSecretAdded"))
    }
    
    // *********************************************************
    // MARK: - Add secret
    // *********************************************************
    func requestAddSecret(secretType: SeedkeeperSecretType) {
        switch secretType {
        case .bip39Mnemonic:
            session = SatocardController(onConnect: onAddMnemonicSecret, onFailure: onDisconnection)
            session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
        case .password:
            session = SatocardController(onConnect: onAddPasswordSecret, onFailure: onDisconnection)
            session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
        default:
            print("requestAddSecret : No action defined for \(secretType.rawValue)")
        }
    }
    
    // SECRET_TYPE_BIP39_MNEMONIC: [mnemonic_size(1b) | mnemonic | passphrase_size(1b) | passphrase ]
    private func onAddMnemonicSecret(cardChannel: CardChannel) -> Void {
        print("onAddMnemonicSecret")
        guard let pinForMasterCard = pinForMasterCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
            // homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
            return
        }
        
        guard let mnemonicPayload = mnemonicPayloadToImportOnCard else {
            session?.stop(errorMessage: String(localized: "nfcPasswordPayloadIsNotDefined"))
            logEvent(log: LogModel(type: .error, message: "onAddMnemonicSecret : mnemonicPayload is not defined"))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
            let secretBytes = mnemonicPayload.getPayloadBytes()
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
            
            self.addSecretToMasterList(secretHeader: SeedkeeperSecretHeaderDto(secretHeader: secretHeader))
                        
            homeNavigationPath.append(NavigationRoutes.generateSuccess(label))
            
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
            logEvent(log: LogModel(type: .error, message: "onAddMnemonicSecret : \(error.localizedDescription)"))
        }
        
        session?.stop(alertMessage: String(localized: "nfcSecretAdded"))
    }
    
    // SECRET_TYPE_PASSWORD (subtype 0x01): [password_size(1b) | password | login_size(1b) | login | url_size(1b) | url]
    private func onAddPasswordSecret(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = pinForMasterCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
            return
        }
        
        guard let passwordPayload = passwordPayloadToImportOnCard else {
            session?.stop(errorMessage: String(localized: "nfcPasswordPayloadIsNotDefined"))
            logEvent(log: LogModel(type: .error, message: "onAddPasswordSecret : passwordPayload is not defined"))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
            let secretBytes = passwordPayload.getPayloadBytes()
            let secretFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: secretBytes)
            
            let label = passwordPayload.label
            
            let secretHeader = SeedkeeperSecretHeader(type: SeedkeeperSecretType.password,
                                                      subtype: UInt8(0x01),
                                                      fingerprintBytes: secretFingerprintBytes,
                                                      label: label)
            let secretObject = SeedkeeperSecretObject(secretBytes: secretBytes,
                                                      secretHeader: secretHeader,
                                                      isEncrypted: false)
            
            let (rapdu, sid, fingerprintBytes) = try cmdSet.seedkeeperImportSecret(secretObject: secretObject)
            
            try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
            
            try checkEqual(fingerprintBytes, secretFingerprintBytes, tag: "Function: \(#function), line: \(#line)")
            
            self.addSecretToMasterList(secretHeader: SeedkeeperSecretHeaderDto(secretHeader: secretHeader))
            
            homeNavigationPath.append(NavigationRoutes.generateSuccess(label))
            
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
            logEvent(log: LogModel(type: .error, message: "onAddPasswordSecret : \(error.localizedDescription)"))
        }
        
        session?.stop(alertMessage: String(localized: "nfcSecretAdded"))
    }
    
    private func addSecretToMasterList(secretHeader: SeedkeeperSecretHeaderDto) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return}
            masterSecretHeaders.append(secretHeader)
        }
    }
    
    // *********************************************************
    // MARK: - Get secret
    // *********************************************************
    func requestGetSecret(with secretHeader: SeedkeeperSecretHeaderDto) {
        currentSecretHeader = secretHeader
        session = SatocardController(onConnect: onGetSecret, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    private func onGetSecret(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = self.pinForMasterCard,
              let currentSecretHeader = self.currentSecretHeader else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var pinResponse = try cmdSet.cardVerifyPIN(pin: pinBytes)
            var result = try cmdSet.seedkeeperExportSecret(sid: currentSecretHeader.sid)
            self.currentSecretObject = result
            session?.stop(alertMessage: String(localized: "nfcSecretFetched"))
            print("seedkeeperExportSecret : \(result)")
        } catch let error {
            logEvent(log: LogModel(type: .error, message: "onGetSecret : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    
    // *********************************************************
    // MARK: - Fetch secrets
    // *********************************************************
    func requestFetchSecrets() {
        session = SatocardController(onConnect: onFetchSecrets, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    private func onFetchSecrets(cardChannel: CardChannel) -> Void  {
        guard let pinForMasterCard = pinForMasterCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
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
            logEvent(log: LogModel(type: .error, message: "onFetchSecrets : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    // *********************************************************
    // MARK: - Delete secret
    // *********************************************************
    // TODO: Not supported for v1
    func requestDeleteSecret() {
        session = SatocardController(onConnect: onDeleteSecret, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    private func onDeleteSecret(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = pinForMasterCard,
              let currentSecretHeader = self.currentSecretHeader else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            var rapdu = try cmdSet.seedkeeperResetSecret(sid: currentSecretHeader.sid)
            try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
            homeNavigationPath.removeLast()
            session?.stop(alertMessage: String(localized: "nfcSecretDeleted"))
        } catch let error {
            logEvent(log: LogModel(type: .error, message: "onDeleteSecret : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    // *********************************************************
    // MARK: - Get Xpub
    // *********************************************************
    // TODO: Not supported for v1
    func requestGetXpub() {
        session = SatocardController(onConnect: onGetXpub, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    private func onGetXpub(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = pinForMasterCard,
              let currentSecretHeader = self.currentSecretHeader else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
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
            logEvent(log: LogModel(type: .error, message: "onGetXpub : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
}
