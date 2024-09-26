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
                self.masterCardLabel = cardLabelToSet
                self.cardLabelToSet = nil
            }
            session?.stop(alertMessage: String(localized: "nfcLabelSetSuccess"))
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
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
                    self.addSecretToMasterList(secretHeader: secretHeader)
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
                    
                } catch let error as StatusWord where error == .secureImportDataTooLong {
                    
                    print("onImportSecret ERROR \(error.localizedDescription)")
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    logEvent(log: LogModel(type: .error, message: "onAddPasswordSecret secret too long: \(error.localizedDescription)"))
                    
                    onFail()
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
    
    private func addSecretToMasterList(secretHeader: SeedkeeperSecretHeader) {
        DispatchQueue.main.async {
            self.masterSecretHeaders.insert(secretHeader, at: 0)
        }
    }
    
    private func addLoginToSavedLoginsDB(login: String) {
        print("addLoginToSavedLoginsDB adding login \(login) to db...")
        dataControllerContext.saveLoginEntry(loginModel: UsedLoginModel(login: login))
    }
    
    // *********************************************************
    // MARK: - Export secret
    // *********************************************************
    
    // TODO: rename to exportSecret
    func requestGetSecret(with secretHeader: SeedkeeperSecretHeader) {
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
            
            DispatchQueue.main.async {
                self.homeNavigationPath.removeLast()
                self.masterSecretHeaders.removeAll { $0 == currentSecretHeader } //
            }
            session?.stop(alertMessage: String(localized: "nfcSecretDeleted"))
            //deleteSecretsFromList(secretHeader: currentSecretHeader)
            
        } catch let error {
            logEvent(log: LogModel(type: .error, message: "onDeleteSecret : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
//    func deleteSecretsFromList(secretHeader: SeedkeeperSecretHeader) {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            self.masterSecretHeaders.removeAll { $0 == secretHeader }
//        }
//    }
    
}
