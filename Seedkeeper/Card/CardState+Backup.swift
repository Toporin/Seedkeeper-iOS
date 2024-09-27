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
    // MARK: Import secrets to the backup card
    // *********************************************************
    func requestImportSecretsToBackupCard() {
        session = SatocardController(onConnect: onImportSecretsToBackupCard, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanBackupCardForImport")) // TODO: change message
    }
    
    func onImportSecretsToBackupCard(cardChannel: CardChannel) -> Void {
        
        logger.info("\(String(localized: "Start import secret to backup card"))", tag: "onImportSecretsToBackupCard")
        
        guard let pinForBackupCard = pinForBackupCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeError"))
            logger.info("\(String(localized: "nfcPinCodeError"))", tag: "onImportSecretsToBackupCard")
            return
        }
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            let pinBytes = Array(pinForBackupCard.utf8)
            do {
                var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            } catch let error as StatusWord where error == .lockError {
                // When nfc session time-out, secret export can be interrupted in the middle of operation.
                // In this case, a lockError can be generated in the next command sent to card.
                // just try again
                var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
                logger.info("LockError - retry", tag: "onImportSecretsToBackupCard")
            }
            
            let isAuthentikeyValid = try isAuthentikeyValid(for: .backup)
            if !isAuthentikeyValid {
                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                logger.error("\(String(localized: "nfcAuthentikeyError"))", tag: "onImportSecretsToBackupCard")
                return
            }
            
            // check whether the backup authentikey is already present in card
            let authentikeySecretBytes = [UInt8(authentikeyBytes!.count)] + authentikeyBytes!
            let authentikeyFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: authentikeySecretBytes)
            var authentikeySid = 0
            if let authentikeyHeader = backupSecretHeaders.first(where: {$0.fingerprintBytes == authentikeyFingerprintBytes}) {
                // the backup authentikey is already store in the card, get its sid
                authentikeySid = authentikeyHeader.sid
                logger.info("Master authentikey is already present in card with sid: \(authentikeySid)", tag: "onImportSecretsToBackupCard")
            } else {
                // the backup authentikey could not be found, so we import it (required to export encrypted secrets)
                authentikeySid = try self.importAuthentikeyAsSecret(for: .master)
                logger.info("Backup authentikey imported in card with sid: \(authentikeySid)", tag: "onImportSecretsToBackupCard")
            }
            
            //for secret in self.secretsForBackup {
            for index in importIndex ..< secretsForBackup.count {
         
                do {
                    let secret = self.secretsForBackup[index]
                    try cmdSet.seedkeeperImportSecret(secretObject: secret, sidPubkey: authentikeySid)
                    
                    DispatchQueue.main.async {
                        self.importIndex = index+1
                    }
                    
                } catch let error as StatusWord where error == .secureImportDataTooLong {
                    // TODO: add to report
                    print("onImportSecretsToBackupCard error during import: \(error)")
                    self.backupError += "Secret \(self.secretsForBackup[index].secretHeader.label) is too long, skipped \n"
                    logger.error("Secret '\(self.secretsForBackup[index].secretHeader.label)' is too long, skipped", tag: "onImportSecretsToBackupCard")
                    
                } catch let error as StatusWord where error == .noMemoryLeft {
                    // TODO: add to report
                    self.backupError = "no memory available! \n"
                    session?.stop(errorMessage: "\(String(localized: "nfcNoMemoryLeft"))")
                    logger.error("\(String(localized: "nfcNoMemoryLeft"))", tag: "onImportSecretsToBackupCard")
                    DispatchQueue.main.async {
                        self.homeNavigationPath.append(NavigationRoutes.backupFailed)
                    }
                    
                } catch {
                    // TODO: add to report
                    self.backupError = "\(error.localizedDescription)"
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    logger.error("\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)", tag: "onImportSecretsToBackupCard")
                    return
                }
                
            } // for
            
            session?.stop(alertMessage: String(localized: "nfcBackupSuccess"))
            logger.info("\(String(localized: "nfcBackupSuccess"))", tag: "onImportSecretsToBackupCard")
            
            DispatchQueue.main.async {
                self.homeNavigationPath.append(NavigationRoutes.backupSuccess)
                self.importIndex = 0
            }
            
        } catch let error {
            print("onImportSecretsToBackupCard error: \(error)")
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
            logger.error("\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)", tag: "onImportSecretsToBackupCard")
        }
    }
    
    // *********************************************************
    // MARK: Export secrets from master card for backup
    // *********************************************************
    
    func requestExportSecretsForBackup(){
        
        session = SatocardController(
            onConnect: { [weak self] cardChannel in
                guard let self = self else { return }
                
                logger.info("Starting export encrypted secrets for backup", tag: "requestExportSecretsForBackup")
                
                guard let pinForMasterCard = pinForMasterCard else {
                    session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
                    logger.info(String(localized: "nfcPinCodeIsNotDefined"), tag: "requestExportSecretsForBackup")
                    DispatchQueue.main.async {
                        self.homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
                    }
                    return
                }
                
                cmdSet = SatocardCommandSet(cardChannel: cardChannel)
                
                do {
                    let pinBytes = Array(pinForMasterCard.utf8)
                    do {
                        var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
                    } catch let error as StatusWord where error == .lockError {
                        // When nfc session time-out, secret export can be interrupted in the middle of operation.
                        // In this case, a lockError can be generated in the next command sent to card.
                        // just try again
                        var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
                        logger.info("LockError - trying again", tag: "requestExportSecretsForBackup")
                    }
                    
                    let isAuthentikeyValid = try isAuthentikeyValid(for: .master)
                    if !isAuthentikeyValid {
                        session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                        logger.error(String(localized: "nfcAuthentikeyError"), tag: "requestExportSecretsForBackup")
                        return
                    }
                    
                    // get the list of secrets headers
                    // these are headers in master but not yet in backup card
                    let secretHeaders: [SeedkeeperSecretHeader] = secretHeadersForBackup
                    
                    // check whether the backup authentikey is already present in card
                    let authentikeySecretBytes = [UInt8(authentikeyBytesForBackup!.count)] + authentikeyBytesForBackup!
                    let authentikeyFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: authentikeySecretBytes)
                    var authentikeySid = 0
                    if let authentikeyHeader = masterSecretHeaders.first(where: {$0.fingerprintBytes == authentikeyFingerprintBytes}) {
                        // the backup authentikey is already store in the card, get its sid
                        authentikeySid = authentikeyHeader.sid
                        logger.info("Backup authentikey is already present in card with sid: \(authentikeySid)", tag: "requestExportSecretsForBackup")
                    } else {
                        // the backup authentikey could not be found, so we import it (required to export encrypted secrets)
                        authentikeySid = try self.importAuthentikeyAsSecret(for: .backup)
                        logger.info("Backup authentikey imported in card with sid: \(authentikeySid)", tag: "requestExportSecretsForBackup")
                    }
                    
                    // we export secrets, possibly on multiple nfc sessions if needed
                    let minIndex = exportIndex
                    for index in minIndex ..< secretHeaders.count {
                        let secretHeader = secretHeaders[index]
                        
                        // check secret type: skip backup authentikey
                        // TODO: perform these checks before initiating scan session for performance
                        // TODO: skip all pubkeys or only the backup authentikey?
                        if secretHeader.type == .pubkey {
                            logger.info("Skip export pubkey with label: '\(secretHeader.label)'", tag: "requestExportSecretsForBackup")
                            continue
                        }
                        
                        let encryptedSecretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid, sidPubkey: authentikeySid)
                        
                        self.secretsForBackup.append(encryptedSecretObject)
                        
                        // update exportIndex so if nfc session timeout, we can start where we left
                        DispatchQueue.main.async {
                            self.exportIndex = index+1
                        }
                        
                        logger.info("Exported secret sid: \(encryptedSecretObject.secretHeader.sid)", tag: "requestExportSecretsForBackup")
                        
                        //sleep(1)// force multiple nfc session - for debug purpose!
                    }
                    session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
                    logger.info(String(localized: "nfcSecretsListSuccess"), tag: "requestExportSecretsForBackup")
                    
                    DispatchQueue.main.async {
                        self.backupMode = .backupExportReady
                        self.exportIndex = 0
                        print("requestExportSecretsForBackupSession DispatchQueue backupMode: \(self.backupMode)")
                    }
                    print("requestExportSecretsForBackupSession backupMode: \(backupMode)")
                    
                } catch let error {
                    print("requestExportSecretsForBackupSession catch error: \(error)")
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    logger.error("\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)", tag: "requestExportSecretsForBackup")
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
    
    func importAuthentikeyAsSecret(for cardType: ScannedCardType) throws -> Int {
        var authentikeySecretBytes = [UInt8]()
        
        if cardType == .master {
            authentikeySecretBytes = [UInt8(authentikeyBytes!.count)] + authentikeyBytes!
        } else if cardType == .backup {
            authentikeySecretBytes = [UInt8(authentikeyBytesForBackup!.count)] + authentikeyBytesForBackup!
        }
        
        let authentikeyFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: authentikeySecretBytes)
        let authentikeyLabel = "Seedkeeper authentikey" //TODO: use better label!
        let authentikeySecretHeader = SeedkeeperSecretHeader(type: SeedkeeperSecretType.pubkey,
                                                  subtype: UInt8(0x00),
                                                  fingerprintBytes: authentikeyFingerprintBytes,
                                                  label: authentikeyLabel)
        let authentikeySecretObject = SeedkeeperSecretObject(secretBytes: authentikeySecretBytes,
                                                  secretHeader: authentikeySecretHeader,
                                                  isEncrypted: false)
        
        let (rapdu2, authentikeySid, fingerprintBytes) = try cmdSet.seedkeeperImportSecret(secretObject: authentikeySecretObject)
        
        return authentikeySid
    }
    
    // *********************************************************
    // MARK: - Backup card - connection
    // *********************************************************
    
    func resetStateForBackupCard(clearPin: Bool = false) {
        print("In resetStateForBackupCard")
        certificateCodeForBackup = .unknown
        //authentikeyBytes = nil
        authentikeyBytesForBackup = nil
        
        importIndex = 0
        exportIndex = 0
        secretsForBackup = []
        backupMode = .start
        if clearPin {
            pinForBackupCard = nil
        }
    }
}
