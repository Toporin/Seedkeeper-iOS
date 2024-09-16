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
            
            var isAuthentikeyValid = try isAuthentikeyValid(for: .master)
            
            if !isAuthentikeyValid {
                logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                return
            }
            
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
    // MARK: - Add secret
    // *********************************************************
//    func requestAddSecret(secretType: SeedkeeperSecretType) {
//        switch secretType {
//        case .bip39Mnemonic:
//            session = SatocardController(onConnect: onAddMnemonicSecret, onFailure: onDisconnection)
//            session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
//        case .password:
//            session = SatocardController(onConnect: onAddPasswordSecret, onFailure: onDisconnection)
//            session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
//        default:
//            print("requestAddSecret : No action defined for \(secretType.rawValue)")
//        }
//    }
    
    // DEPRECATED : SECRET_TYPE_BIP39_MNEMONIC: [mnemonic_size(1b) | mnemonic | passphrase_size(1b) | passphrase ]
    // SECRET_TYPE_MASTER_SEED (subtype SECRET_SUBTYPE_BIP39): [ masterseed_size(1b) | masterseed | wordlist_selector(1b) | entropy_size(1b) | entropy(<=32b) | passphrase_size(1b) | passphrase] where entropy is 16-32 bytes as defined in BIP39 (this format is backward compatible with SECRET_TYPE_MASTER_SEED)
//    private func onAddMnemonicSecret(cardChannel: CardChannel) -> Void {
//        print("onAddMnemonicSecret")
//        guard let pinForMasterCard = pinForMasterCard else {
//            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
//            }
//            // homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
//            return
//        }
//        
//        guard let mnemonicPayload = mnemonicPayloadToImportOnCard else {
//            session?.stop(errorMessage: String(localized: "nfcPasswordPayloadIsNotDefined"))
//            logEvent(log: LogModel(type: .error, message: "onAddMnemonicSecret : mnemonicPayload is not defined"))
//            return
//        }
//        
//        let pinBytes = Array(pinForMasterCard.utf8)
//        
//        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
//        
//        do {
//            print("onAddMnemonicSecret verifying PIN...")
//            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
//            
//            print("onAddMnemonicSecret checking authentikey...")
//            var isAuthentikeyValid = try isAuthentikeyValid(for: .master)
//            
//            if !isAuthentikeyValid {
//                logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
//                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
//                return
//            }
//            
//            print("onAddMnemonicSecret checking version...")
//            // TODO: use version or remove
//            guard let cardVersion = self.cardStatus?.appletMinorVersion else {
//                session?.stop(errorMessage: String(localized: "nfcCardVersionIsNotDefined"))
//                return
//            }
//                        
//            let label = mnemonicPayload.label
//            
//            let secretBytes = mnemonicPayload.getPayloadBytes()
//            let secretFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: secretBytes)
//            
//            var secretHeader = SeedkeeperSecretHeader(type: SeedkeeperSecretType.masterseed,
//                                                      subtype: UInt8(0x01),
//                                                      fingerprintBytes: secretFingerprintBytes,
//                                                      label: label)
//            
//            let secretObject = SeedkeeperSecretObject(secretBytes: secretBytes,
//                                                      secretHeader: secretHeader,
//                                                      isEncrypted: false)
//            
//            print("onAddMnemonicSecret importing secret...")
//            let (rapdu, sid, fingerprintBytes) = try cmdSet.seedkeeperImportSecret(secretObject: secretObject)
//            
//            try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
//            try checkEqual(fingerprintBytes, secretFingerprintBytes, tag: "Function: \(#function), line: \(#line)")
//            
//            secretHeader.sid = sid
//            print("onAddMnemonicSecret secret sid: \(sid)")
//            
//            print("onAddMnemonicSecret adding secret header to masterlist...")
//            self.addSecretToMasterList(secretHeader: SeedkeeperSecretHeaderDto(secretHeader: secretHeader))
//                        
//            print("onAddMnemonicSecret setting homeNavigation...")
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                homeNavigationPath.append(NavigationRoutes.generateSuccess(label))
//            }
//            print("onAddMnemonicSecret after homeNavigation")
//            
//        } catch let error {
//            print("onAddMnemonicSecret ERROR \(error.localizedDescription)")
//            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//            logEvent(log: LogModel(type: .error, message: "onAddMnemonicSecret : \(error.localizedDescription)"))
//        }
//        
//        print("onAddMnemonicSecret stopping session...")
//        session?.stop(alertMessage: String(localized: "nfcSecretAdded"))
//        print("onAddMnemonicSecret session stopped!")
//    }
//    
    // SECRET_TYPE_PASSWORD (subtype 0x01): [password_size(1b) | password | login_size(1b) | login | url_size(1b) | url]
//    private func onAddPasswordSecret(cardChannel: CardChannel) -> Void {
//        guard let pinForMasterCard = pinForMasterCard else {
//            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
//            }
//            return
//        }
//        
//        guard let passwordPayload = passwordPayloadToImportOnCard else {
//            session?.stop(errorMessage: String(localized: "nfcPasswordPayloadIsNotDefined"))
//            logEvent(log: LogModel(type: .error, message: "onAddPasswordSecret : passwordPayload is not defined"))
//            return
//        }
//        
//        let pinBytes = Array(pinForMasterCard.utf8)
//        
//        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
//        
//        do {
//            print("onAddPasswordSecret verifying PIN...")
//            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
//            
//            print("onAddPasswordSecret checking authentikey...")
//            var isAuthentikeyValid = try isAuthentikeyValid(for: .master)
//            
//            if !isAuthentikeyValid {
//                logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
//                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
//                return
//            }
//            
//            let secretBytes = passwordPayload.getPayloadBytes()
//            let secretFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: secretBytes)
//            
//            let label = passwordPayload.label
//            
//            var secretHeader = SeedkeeperSecretHeader(type: SeedkeeperSecretType.password,
//                                                      subtype: UInt8(0x01),
//                                                      fingerprintBytes: secretFingerprintBytes,
//                                                      label: label)
//            let secretObject = SeedkeeperSecretObject(secretBytes: secretBytes,
//                                                      secretHeader: secretHeader,
//                                                      isEncrypted: false)
//            
//            print("onAddPasswordSecret importing secret on card...")
//            let (rapdu, sid, fingerprintBytes) = try cmdSet.seedkeeperImportSecret(secretObject: secretObject)
//            
//            try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
//            try checkEqual(fingerprintBytes, secretFingerprintBytes, tag: "Function: \(#function), line: \(#line)")
//            
//            secretHeader.sid = sid
//            print("onAddPasswordSecret secret imported with sid: \(sid)")
//            
//            print("onAddPasswordSecret adding new secret header to master list...")
//            self.addSecretToMasterList(secretHeader: SeedkeeperSecretHeaderDto(secretHeader: secretHeader))
//            print("onAddPasswordSecret added secret header to master list")
//            
//            if let login = passwordPayload.login {
//                self.addLoginToSavedLoginsDB(login: login)
//            }
//            
//            print("onAddPasswordSecret calling home navigation path with label: \(label)...")
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                homeNavigationPath.append(NavigationRoutes.generateSuccess(label))
//            }
//            print("onAddPasswordSecret called home navigation path !")
//            
//        } catch let error {
//            print("onAddPasswordSecret ERROR \(error.localizedDescription)")
//            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//            logEvent(log: LogModel(type: .error, message: "onAddPasswordSecret : \(error.localizedDescription)"))
//        }
//        
//        print("onAddPasswordSecret stopping session...")
//        session?.stop(alertMessage: String(localized: "nfcSecretAdded"))
//        print("onAddPasswordSecret session stopped!")
//    }
    
    
    // *********************************************************
    // MARK: - Import secret
    // *********************************************************
    
    func requestImportSecret(secretPayload: Payload, onSuccess: @escaping () -> Void, onFail: @escaping () -> Void){
        session = SatocardController(
            onConnect: { [weak self] cardChannel in
                guard let self = self else { return }
                
                guard let pinForMasterCard = pinForMasterCard else {
                    session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
                    }
                    return
                }
                let pinBytes = Array(pinForMasterCard.utf8)
                
                cmdSet = SatocardCommandSet(cardChannel: cardChannel)
                
                do {
                    print("onImportSecret verifying PIN...")
                    var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
                    
                    print("onImportSecret checking authentikey...")
                    var isAuthentikeyValid = try isAuthentikeyValid(for: .master)
                    
                    if !isAuthentikeyValid {
                        logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
                        session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                        return
                    }
                    
                    var secretHeader = SeedkeeperSecretHeader(type: secretPayload.type,
                                                              subtype: secretPayload.subtype,
                                                              fingerprintBytes: secretPayload.getFingerprintBytes(),
                                                              label: secretPayload.label)
                    let secretObject = SeedkeeperSecretObject(secretBytes: secretPayload.getPayloadBytes(),
                                                              secretHeader: secretHeader,
                                                              isEncrypted: false)
                    
                    print("onImportSecret importing secret on card...")
                    let (rapdu, sid, fingerprintBytes) = try cmdSet.seedkeeperImportSecret(secretObject: secretObject)
                    
                    try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
                    try checkEqual(fingerprintBytes, secretHeader.fingerprintBytes, tag: "Function: \(#function), line: \(#line)")
                    
                    secretHeader.sid = sid
                    print("onImportSecret secret imported with sid: \(sid)")
                    
                    print("onImportSecret adding new secret header to master list...")
                    self.addSecretToMasterList(secretHeader: SeedkeeperSecretHeaderDto(secretHeader: secretHeader))
                    print("onImportSecret added secret header to master list")
                    
                    // specific to password
                    if secretPayload.type == SeedkeeperSecretType.password {
                        if let passwordPayload = secretPayload as? PasswordPayload {
                            if let login = passwordPayload.login {
                                self.addLoginToSavedLoginsDB(login: login)
                            }
                        }
                    }
                    
                    print("onImportSecret calling home navigation path with label: \(secretPayload.label)...")
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        homeNavigationPath.append(NavigationRoutes.generateSuccess(secretPayload.label))
                    }
                    print("onImportSecret called home navigation path !")
                    
                    print("onImportSecret stopping session...")
                    session?.stop(alertMessage: String(localized: "nfcSecretAdded"))
                    print("onImportSecret session stopped!")
                    
                    onSuccess()
                    
                } catch let error {
                    print("onImportSecret ERROR \(error.localizedDescription)")
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    logEvent(log: LogModel(type: .error, message: "onAddPasswordSecret : \(error.localizedDescription)"))
                    
                    onFail()
                }
                
            },
            onFailure: { [weak self] error in
                // these are errors related to NFC communication
                guard let self = self else { return }
                self.onDisconnection(error: error)
            }
        )// session

        session?.start(alertMessage: String(localized: "nfcScanMasterCard")) // TODO: change txt? nfcHoldSatodime
    }
    
//    func requestImportSecret(secretPayload: Payload) {
//        session = SatocardController(onConnect: onImportSecret, onFailure: onDisconnection)
//        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
//    }
    
//    private func onImportSecret(cardChannel: CardChannel) -> Void {
//        
//        guard let passwordPayload = secretPayloadToImportOnCard else {
//            session?.stop(errorMessage: String(localized: "nfcPayloadIsNotDefined"))
//            logEvent(log: LogModel(type: .error, message: "onImportSecret : secretPayload is not defined"))
//            return
//        }
//        
//        guard let pinForMasterCard = pinForMasterCard else {
//            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
//            }
//            return
//        }
//        let pinBytes = Array(pinForMasterCard.utf8)
//        
//        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
//        
//        do {
//            print("onImportSecret verifying PIN...")
//            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
//            
//            print("onImportSecret checking authentikey...")
//            var isAuthentikeyValid = try isAuthentikeyValid(for: .master)
//            
//            if !isAuthentikeyValid {
//                logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
//                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
//                return
//            }
//            
//            let secretBytes = passwordPayload.getPayloadBytes()
//            let secretFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: secretBytes)
//            
//            let label = passwordPayload.label
//            
//            var secretHeader = SeedkeeperSecretHeader(type: secretPayload.type,
//                                                      subtype: secretPayload.subtype,
//                                                      fingerprintBytes: secretPayload.getFingerprintBytes(),
//                                                      label: secretPayload.label)
//            let secretObject = SeedkeeperSecretObject(secretBytes: secretBytes,
//                                                      secretHeader: secretHeader,
//                                                      isEncrypted: false)
//            
//            print("onImportSecret importing secret on card...")
//            let (rapdu, sid, fingerprintBytes) = try cmdSet.seedkeeperImportSecret(secretObject: secretObject)
//            
//            try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
//            try checkEqual(fingerprintBytes, secretFingerprintBytes, tag: "Function: \(#function), line: \(#line)")
//            
//            secretHeader.sid = sid
//            print("onImportSecret secret imported with sid: \(sid)")
//            
//            print("onImportSecret adding new secret header to master list...")
//            self.addSecretToMasterList(secretHeader: SeedkeeperSecretHeaderDto(secretHeader: secretHeader))
//            print("onImportSecret added secret header to master list")
//            
//            if let login = passwordPayload.login {
//                self.addLoginToSavedLoginsDB(login: login)
//            }
//            
//            print("onImportSecret calling home navigation path with label: \(label)...")
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                homeNavigationPath.append(NavigationRoutes.generateSuccess(label))
//            }
//            print("onImportSecret called home navigation path !")
//            
//        } catch let error {
//            print("onImportSecret ERROR \(error.localizedDescription)")
//            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//            logEvent(log: LogModel(type: .error, message: "onAddPasswordSecret : \(error.localizedDescription)"))
//        }
//        
//        print("onImportSecret stopping session...")
//        session?.stop(alertMessage: String(localized: "nfcSecretAdded"))
//        print("onImportSecret session stopped!")
//    }
//    
    
    private func addSecretToMasterList(secretHeader: SeedkeeperSecretHeaderDto) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            masterSecretHeaders.insert(secretHeader, at: 0)
        }
    }
    
    /*private func addSecretToMasterList(secretHeader: SeedkeeperSecretHeaderDto) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return}
            masterSecretHeaders.append(secretHeader)
        }
    }*/
    
    private func addLoginToSavedLoginsDB(login: String) {
        print("addLoginToSavedLoginsDB adding login \(login) to db...")
        dataControllerContext.saveLoginEntry(loginModel: UsedLoginModel(login: login))
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
            
            var isAuthentikeyValid = try isAuthentikeyValid(for: .master)
            
            if !isAuthentikeyValid {
                logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                return
            }
            
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
            
            var isAuthentikeyValid = try isAuthentikeyValid(for: .master)
            
            if !isAuthentikeyValid {
                logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                return
            }
            
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
            
            var isAuthentikeyValid = try isAuthentikeyValid(for: .master)
            
            if !isAuthentikeyValid {
                logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                return
            }
            
            var rapdu = try cmdSet.seedkeeperResetSecret(sid: currentSecretHeader.sid)
            try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
            homeNavigationPath.removeLast()
            session?.stop(alertMessage: String(localized: "nfcSecretDeleted"))
            deleteSecretsFromList(secretHeader: currentSecretHeader)
        } catch let error {
            logEvent(log: LogModel(type: .error, message: "onDeleteSecret : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    func deleteSecretsFromList(secretHeader: SeedkeeperSecretHeaderDto) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.masterSecretHeaders.removeAll { $0 == secretHeader }
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
