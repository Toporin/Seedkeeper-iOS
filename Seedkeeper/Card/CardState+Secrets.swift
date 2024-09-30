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
            logger.info(String(localized: "nfcPinCodeIsNotDefined"), tag: "onSetCardLabel")
            DispatchQueue.main.async {
                self.homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
            }
            return
        }
        
        guard let cardLabelToSet = cardLabelToSet else {
            session?.stop(errorMessage: String(localized: "nfcCardLabelIsNotDefined"))
            logger.info(String(localized: "nfcCardLabelIsNotDefined"), tag: "onSetCardLabel")
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            let rapdu = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
            let isAuthentikeyValid = try isAuthentikeyValid(for: .master)
            if !isAuthentikeyValid {
                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                logger.error("\(String(localized: "nfcAuthentikeyError"))", tag: "onSetCardLabel")
                return
            }
            
            let isOk = try cmdSet.cardSetLabel(label: cardLabelToSet)
            if isOk {
                DispatchQueue.main.async {
                    self.masterCardLabel = cardLabelToSet
                    self.cardLabelToSet = nil
                    self.homeNavigationPath.removeLast()
                }
            }
            
            session?.stop(alertMessage: String(localized: "nfcLabelSetSuccess"))
            logger.info("\(String(localized: "nfcLabelSetSuccess"))", tag: "onSetCardLabel")
            
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
            logger.error("\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)", tag: "onSetCardLabel")
        }
        
        
    }
    
    // *********************************************************
    // MARK: - Import secret
    // *********************************************************
    
    func requestImportSecret(secretPayload: Payload){
        session = SatocardController(
            onConnect: { [weak self] cardChannel in
                guard let self = self else { return }
                
                guard let pinForMasterCard = pinForMasterCard else {
                    session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
                    logger.info("\(String(localized: "nfcPinCodeIsNotDefined"))", tag: "requestImportSecret")
                    DispatchQueue.main.async {
                        self.homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
                    }
                    return
                }
                let pinBytes = Array(pinForMasterCard.utf8)
                
                cmdSet = SatocardCommandSet(cardChannel: cardChannel)
                
                do {
                    let response = try cmdSet.cardVerifyPIN(pin: pinBytes)
                    
                    let isAuthentikeyValid = try isAuthentikeyValid(for: .master)
                    if !isAuthentikeyValid {
                        session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                        logger.error("\(String(localized: "nfcAuthentikeyError"))", tag: "requestImportSecret")
                        return
                    }
                    
                    var secretHeader = SeedkeeperSecretHeader(type: secretPayload.type,
                                                              subtype: secretPayload.subtype,
                                                              fingerprintBytes: secretPayload.getFingerprintBytes(),
                                                              label: secretPayload.label)
                    let secretObject = SeedkeeperSecretObject(secretBytes: secretPayload.getPayloadBytes(),
                                                              secretHeader: secretHeader,
                                                              isEncrypted: false)
                    
                    let (rapdu, sid, fingerprintBytes) = try cmdSet.seedkeeperImportSecret(secretObject: secretObject)
                    try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
                    try checkEqual(fingerprintBytes, secretHeader.fingerprintBytes, tag: "Function: \(#function), line: \(#line)")
                    
                    session?.stop(alertMessage: String(localized: "nfcSecretAdded"))
                    logger.info("\(String(localized: "nfcSecretAdded")) - sid: \(sid)", tag: "requestImportSecret")
                    
                    secretHeader.sid = sid
                    DispatchQueue.main.async {
                        self.masterSecretHeaders.insert(secretHeader, at: 0)
                    }
                    
                    // save login (specific to password)
                    if secretPayload.type == SeedkeeperSecretType.password {
                        if let passwordPayload = secretPayload as? PasswordPayload {
                            if let login = passwordPayload.login {
                                dataControllerContext.saveLoginEntry(loginModel: UsedLoginModel(login: login))
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.homeNavigationPath.append(NavigationRoutes.generateSuccess(secretPayload.label))
                    }
                    
                } catch let error as StatusWord where error == .secureImportDataTooLong {
                    session?.stop(errorMessage: "\(String(localized: "nfcSecretTooLong"))")
                    logger.error("\(String(localized: "nfcSecretTooLong")) \(error.localizedDescription)", tag: "requestImportSecret")
                } catch let error as StatusWord where error == .noMemoryLeft {
                    session?.stop(errorMessage: "\(String(localized: "nfcNoMemoryLeft"))")
                    logger.error("\(String(localized: "nfcNoMemoryLeft")) \(error.localizedDescription)", tag: "requestImportSecret")
                } catch let error {
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    logger.error("\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)", tag: "requestImportSecret")
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
    
    // *********************************************************
    // MARK: - Export secret
    // *********************************************************
    
    // TODO: rename to exportSecret
    func requestExportSecret(with secretHeader: SeedkeeperSecretHeader) {
        currentSecretHeader = secretHeader
        session = SatocardController(onConnect: onExportSecret, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    private func onExportSecret(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = self.pinForMasterCard,
              let currentSecretHeader = self.currentSecretHeader else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            logger.info("\(String(localized: "nfcPinCodeIsNotDefined"))", tag: "onExportSecret")
            DispatchQueue.main.async {
                self.homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
            }
            return
        }
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            let pinBytes = Array(pinForMasterCard.utf8)
            var pinResponse = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
            let isAuthentikeyValid = try isAuthentikeyValid(for: .master)
            if !isAuthentikeyValid {
                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                logger.error("\(String(localized: "nfcAuthentikeyError"))", tag: "onExportSecret")
                return
            }
            
            var secret = try cmdSet.seedkeeperExportSecret(sid: currentSecretHeader.sid)
            
            DispatchQueue.main.async {
                self.currentSecretObject = secret
            }
            session?.stop(alertMessage: String(localized: "nfcSecretFetched"))
            logger.info("\(String(localized: "nfcSecretFetched"))", tag: "onExportSecret")
            
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
            logger.error("\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)", tag: "onExportSecret")
        }
    }
    
    // *********************************************************
    // MARK: - Delete secret
    // *********************************************************
    
    // TODO: ask for confirmation?
    func requestDeleteSecret() {
        session = SatocardController(onConnect: onDeleteSecret, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    private func onDeleteSecret(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = pinForMasterCard,
              let currentSecretHeader = self.currentSecretHeader else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            logger.info("\(String(localized: "nfcPinCodeIsNotDefined"))", tag: "onDeleteSecret")
            DispatchQueue.main.async {
                self.homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
            }
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            _ = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
            let isAuthentikeyValid = try isAuthentikeyValid(for: .master)
            if !isAuthentikeyValid {
                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                logger.error("\(String(localized: "nfcAuthentikeyError"))", tag: "onDeleteSecret")
                return
            }
            
            let rapdu = try cmdSet.seedkeeperResetSecret(sid: currentSecretHeader.sid)
            try checkEqual(rapdu.sw, StatusWord.ok.rawValue, tag: "Function: \(#function), line: \(#line)")
            
            DispatchQueue.main.async {
                self.homeNavigationPath.removeLast()
                self.masterSecretHeaders.removeAll { $0 == currentSecretHeader }
            }
            session?.stop(alertMessage: String(localized: "nfcSecretDeleted"))
            logger.info("\(String(localized: "nfcSecretDeleted"))", tag: "onDeleteSecret")
            
        } catch let error {
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
            logger.info("\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)", tag: "onDeleteSecret")
        }
    }
    
}
