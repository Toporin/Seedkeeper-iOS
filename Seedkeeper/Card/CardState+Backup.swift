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
        session?.start(alertMessage: String(localized: "nfcScanBackupCardForImport"))
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
            
            var isAuthentikeyValid = try isAuthentikeyValid(for: .backup)
            
            if !isAuthentikeyValid {
                logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                return
            }
            
            self.importAuthentikeyAsSecret(for: .master)
            
            var onBackupAvailableSecretHeaders: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
            
            for secret in self.secretsForBackup {
                
                let secretFingerPrint = secret.key.fingerprintBytes
                if onBackupAvailableSecretHeaders.contains(where: { $0.fingerprintBytes == secretFingerPrint }) {
                    continue
                }
                
                do {
                    var secretBuffer = secret
                    secretBuffer.value.isEncrypted = true
                    
                    var secretEncryptedParamsBuffer = SeedkeeperSecretEncryptedParams(sidPubkey: self.masterAuthentiKeySid!, iv: secretBuffer.value.secretEncryptedParams?.iv ?? [], hmac: secretBuffer.value.secretEncryptedParams?.hmac ?? [])

                    secretBuffer.value.secretEncryptedParams = secretEncryptedParamsBuffer
                    
                    try cmdSet.seedkeeperImportSecret(secretObject: secretBuffer.value)
                } catch {
                    logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : \(error.localizedDescription)"))
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    return
                }
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
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    func onFetchSecretsForBackup(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = pinForMasterCard else {
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
            
            self.importAuthentikeyAsSecret(for: .backup)
            
            var secretHeaders: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
            
            var fetchedSecretsFromCard: [SeedkeeperSecretHeaderDto:SeedkeeperSecretObject] = [:]
            
            for secretHeader in secretHeaders {
                var secretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid)
                
                var encryptedResult = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid, sidPubkey: self.backupAuthentiKeySid!)
                
                fetchedSecretsFromCard[SeedkeeperSecretHeaderDto(secretHeader: secretHeader)] = encryptedResult
            }
            
            self.secretsForBackup = fetchedSecretsFromCard
            
            print("secretsToImport : \(fetchedSecretsFromCard)")
            mode = .backupExportReady
            session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
        } catch let error {
            logEvent(log: LogModel(type: .error, message: "onFetchSecretsForBackup : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    func importAuthentikeyAsSecret(for cardType: ScannedCardType) {
        do {
            var authentikeySecretBytes = [UInt8]()
            
            if cardType == .master {
                authentikeySecretBytes = [UInt8(authentikeyBytes!.count)] + authentikeyBytes!
            } else if cardType == .backup {
                authentikeySecretBytes = [UInt8(authentikeyBytesForBackup!.count)] + authentikeyBytesForBackup!
            }
            
            let authentikeyFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: authentikeySecretBytes)
            let authentikeyLabel = "Seedkeeper authentikey"
            let authentikeySecretHeader = SeedkeeperSecretHeader(type: SeedkeeperSecretType.pubkey,
                                                      subtype: UInt8(0x00),
                                                      fingerprintBytes: authentikeyFingerprintBytes,
                                                      label: authentikeyLabel)
            let authentikeySecretObject = SeedkeeperSecretObject(secretBytes: authentikeySecretBytes,
                                                      secretHeader: authentikeySecretHeader,
                                                      isEncrypted: false)
            
            let (rapdu2, authentikeySid, fingerprintBytes) = try cmdSet.seedkeeperImportSecret(secretObject: authentikeySecretObject)
            
            if cardType == .master {
                self.masterAuthentiKeyBytes = authentikeyBytes
                self.masterAuthentiKeySid = authentikeySid
                self.masterAuthentiKeyFingerprintBytes = fingerprintBytes
            } else if cardType == .backup {
                self.backupAuthentiKeyBytes = authentikeyBytes
                self.backupAuthentiKeySid = authentikeySid
                self.backupAuthentiKeyFingerprintBytes = fingerprintBytes
            }
            
        } catch {
            logEvent(log: LogModel(type: .error, message: "importAuthentikeyAsSecret : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    // *********************************************************
    // MARK: - Backup card - connection
    // *********************************************************
    func scanBackupCard() {
        print("CardState scan()")
        session = SatocardController(onConnect: onConnectionForBackupCard, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanBackupCard"))
    }
    
    func resetStateForBackupCard(clearPin: Bool = false) {
        certificateCodeForBackup = .unknown
        authentikeyHexForBackup = ""
        authentikeyBytes = nil
        authentikeyBytesForBackup = nil
        
        masterAuthentiKeySid = nil
        masterAuthentiKeyBytes = nil
        masterAuthentiKeyFingerprintBytes = nil
        
        backupAuthentiKeySid = nil
        backupAuthentiKeyBytes = nil
        backupAuthentiKeyFingerprintBytes = nil
        
        secretsForBackup = [:]
        mode = .start
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
            // let version = getCardVersionInt(cardStatus: cardStatus)
            // if version <= 0x00010001 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                homeNavigationPath.append(NavigationRoutes.createPinCode(PinCodeNavigationData(mode: .createPinCodeForBackupCard, pinCode: nil)))
            }
            session?.stop(alertMessage: String(localized: "nfcSatodimeNeedsSetup"))
            return
            // }
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
            } catch CardError.wrongPIN(let retryCounter){
                self.pinForBackupCard = nil
                logEvent(log: LogModel(type: .error, message: "onVerifyPin (Backup) : \("\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)"))"))
                if retryCounter == 0 {
                    logEvent(log: LogModel(type: .error, message: "onVerifyPin : \(String(localized: "nfcWrongPinBlocked"))"))
                    self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
                } else {
                    self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)")
                }
                return
                // TODO: NB: CardError.pinBlocked is not returned when pin is blocked on card
            } catch CardError.pinBlocked {
                self.pinForBackupCard = nil
                logEvent(log: LogModel(type: .error, message: "onVerifyPin (Backup) : \(String(localized: "nfcWrongPinBlocked"))"))
                self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
                return
            } catch {
                self.pinForBackupCard = nil
                logEvent(log: LogModel(type: .error, message: "handleConnection : \(error.localizedDescription)"))
                self.session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                return
            }
        }
        
        try await verifyCardAuthenticity(cardType: .backup)
        try await fetchAuthentikey(cardType: .backup)
                
        // self.importAuthentikeyAsSecret(for: .backup)
        
        self.mode = .backupImport
        
        session?.stop(alertMessage: String(localized: "nfcBackupCardPairedSuccess"))
    }
}
