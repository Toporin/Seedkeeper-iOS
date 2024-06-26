//
//  CardState+Backup.swift
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
    // MARK: - Backup card - export secrets to the card
    // *********************************************************
    func requestImportSecretsToBackupCard() {
        session = SatocardController(onConnect: onImportSecretsToBackupCard, onFailure: onDisconnection)
        session?.start(alertMessage: "nfcScanBackupCardForImport")
    }
    
    func onImportSecretsToBackupCard(cardChannel: CardChannel) -> Void {
        guard let pinForBackupCard = pinForBackupCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeError"))
            return
        }
        
        let pinBytes = Array(pinForBackupCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
            for secret in self.secretsForBackup {
                try cmdSet.seedkeeperImportSecret(secretObject: secret.value)
            }
            
            session?.stop(alertMessage: String(localized: "nfcBackupSuccess"))
            
            homeNavigationPath.append(NavigationRoutes.backupSuccess)
        } catch let error {
            logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    // *********************************************************
    // MARK: - Master card - import secrets from card for backup
    // *********************************************************
    func requestFetchSecretsForBackup() {
        session = SatocardController(onConnect: onFetchSecretsForBackup, onFailure: onDisconnection)
        session?.start(alertMessage: "Scan your card")
    }
    
    func onFetchSecretsForBackup(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = pinForMasterCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            return
        }
        
        let pinBytes = Array(pinForMasterCard.utf8)
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            var secretHeaders: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
            
            var fetchedSecretsFromCard: [SeedkeeperSecretHeaderDto:SeedkeeperSecretObject] = [:]
            
            for secretHeader in secretHeaders {
                var secretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid)
                
                var encryptedResult = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid, sidPubkey: secretObject.getSidPubKey())
                
                fetchedSecretsFromCard[SeedkeeperSecretHeaderDto(secretHeader: secretHeader)] = encryptedResult
            }
            
            self.secretsForBackup = fetchedSecretsFromCard
            
            print("secretsToImport : \(fetchedSecretsFromCard)")
            mode = .backupExport
            session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
        } catch let error {
            logEvent(log: LogModel(type: .error, message: "onFetchSecretsForBackup : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    // *********************************************************
    // MARK: - Backup card - connection
    // *********************************************************
    func scanBackupCard() {
        print("CardState scan()")
        DispatchQueue.main.async {
            self.resetStateForBackupCard()
        }
        session = SatocardController(onConnect: onConnectionForBackupCard, onFailure: onDisconnection)
        session?.start(alertMessage: "nfcScanBackupCard")
    }
    
    func resetStateForBackupCard(clearPin: Bool = false) {
        certificateCodeForBackup = .unknown
        authentikeyHexForBackup = ""
        secretsForBackup = [:]
        if clearPin {
            pinForBackupCard = nil
        }
    }
    
    func onConnectionForBackupCard(cardChannel: CardChannel) -> Void {
        Task {
            do {
                try await handleConnectionForBackupCard(cardChannel: cardChannel)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)"
                }
                logEvent(log: LogModel(type: .error, message: "onConnectionForBackupCard : \(error.localizedDescription)"))
                session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
            }
        }
    }
    
    private func handleConnectionForBackupCard(cardChannel: CardChannel) async throws {
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        let (statusApdu, cardType) = try await fetchCardStatus()

        backupCardStatus = try CardStatus(rapdu: statusApdu)
        
        if let cardStatus = backupCardStatus, !cardStatus.setupDone {
            let version = getCardVersionInt(cardStatus: cardStatus)
            if version <= 0x00010001 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    homeNavigationPath.append(NavigationRoutes.createPinCode(PinCodeNavigationData(mode: .createPinCodeForBackupCard, pinCode: nil)))
                }
                session?.stop(alertMessage: String(localized: "nfcSatodimeNeedsSetup"))
                return
            }
        } else {
            guard let pinForBackupCard = pinForBackupCard else {
                session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    homeNavigationPath.append(NavigationRoutes.pinCode(.continueBackupFlow))
                }
                return
            }
            
            let pinBytes = Array(pinForBackupCard.utf8)
            do {
                var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            } catch {
                self.pinForBackupCard = nil
                self.logEvent(log: LogModel(type: .error, message: "handleConnectionForBackupCard : \(error.localizedDescription)"))
                self.session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                return
            }
        }
        
        try await verifyCardAuthenticity(cardType: .backup)
        try await fetchAuthentikey(cardType: .backup)
        
        self.mode = .backupImport
        
        session?.stop(alertMessage: String(localized: "nfcBackupCardPairedSuccess"))
    }
}
