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
        guard let pinForBackupCard = pinForBackupCard else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeError"))
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
                print("onImportSecretsToBackupCard catch error: \(error)")
                logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : \(error.localizedDescription)"))
            }
            
            let isAuthentikeyValid = try isAuthentikeyValid(for: .backup)
            if !isAuthentikeyValid {
                logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                return
            }
            
            // check whether the backup authentikey is already present in card
            let authentikeySecretBytes = [UInt8(authentikeyBytes!.count)] + authentikeyBytes!
            let authentikeyFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: authentikeySecretBytes)
            var authentikeySid = 0
            if let authentikeyHeader = backupSecretHeaders.first(where: {$0.fingerprintBytes == authentikeyFingerprintBytes}) {
                // the backup authentikey is already store in the card, get its sid
                authentikeySid = authentikeyHeader.sid
                print("Master authentikey is already present in card with sid: \(authentikeySid)")
            } else {
                // the backup authentikey could not be found, so we import it (required to export encrypted secrets)
                authentikeySid = try self.importAuthentikeyAsSecret(for: .master)
                print("Backup authentikey imported in card with sid: \(authentikeySid)")
            }
            
            //for secret in self.secretsForBackup {
            for index in importIndex ..< secretsForBackup.count {
         
                do {
                    let secret = self.secretsForBackup[index]
                    try cmdSet.seedkeeperImportSecret(secretObject: secret, sidPubkey: authentikeySid)
                    
                    // TODO: check rapdu
                    
                    importIndex = index+1 // todo: dispatchQueue
                    
                } catch let error as StatusWord where error == .secureImportDataTooLong {
                    // TODO: add to report
                    print("onImportSecretsToBackupCard error during import: \(error)")
                    self.backupError += "Secret \(self.secretsForBackup[index].secretHeader.label) is too long, skipped"
                    logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : \(error.localizedDescription)"))
                    
                } catch let error as StatusWord where error == .noMemoryLeft {
                    // TODO: add to report
                    print("onImportSecretsToBackupCard error during import: \(error)")
                    self.backupError = "no memory available!"
                    logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : \(error.localizedDescription)"))
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.homeNavigationPath.append(NavigationRoutes.backupFailed)
                    }
                    
                } catch {
                    // TODO: add to report
                    print("onImportSecretsToBackupCard error during import: \(error)")
                    self.backupError = "\(error.localizedDescription)"
                    logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : \(error.localizedDescription)"))
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    return // TODO: something depending of error type?
                }
                
            } // for
            
            session?.stop(alertMessage: String(localized: "nfcBackupSuccess"))
            
            DispatchQueue.main.async {
                self.homeNavigationPath.append(NavigationRoutes.backupSuccess)
                self.importIndex = 0
            }
            
            
        } catch let error {
            print("onImportSecretsToBackupCard error: \(error)")
            logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
    }
    
    // *********************************************************
    // MARK: Export secrets from master card for backup
    // *********************************************************
    
    func requestExportSecretsForBackup(){
        
        session = SatocardController(
            onConnect: { [weak self] cardChannel in
                guard let self = self else { return }

                guard let pinForMasterCard = pinForMasterCard else {
                    session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
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
                        print("requestExportSecretsForBackupSession catch error: \(error)")
                        logEvent(log: LogModel(type: .error, message: "onFetchSecretsForBackup : \(error.localizedDescription)"))
                    }
                    
                    let isAuthentikeyValid = try isAuthentikeyValid(for: .master)
                    if !isAuthentikeyValid {
                        logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
                        session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
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
                        print("Backup authentikey is already present in card with sid: \(authentikeySid)")
                    } else {
                        // the backup authentikey could not be found, so we import it (required to export encrypted secrets)
                        authentikeySid = try self.importAuthentikeyAsSecret(for: .backup)
                        print("Backup authentikey imported in card with sid: \(authentikeySid)")
                    }
                    
                    // we export secrets, possibly on multiple nfc sessions if needed
                    let minIndex = exportIndex
                    for index in minIndex ..< secretHeaders.count {
                        let secretHeader = secretHeaders[index]
                        
                        // check secret type: skip backup authentikey
                        // TODO: perform these checks before initiating scan session for performance
                        // TODO: skip all pubkeys or only the backup authentikey?
                        if secretHeader.type == .pubkey {
                            // TODO: log
                            continue
                        }
                        
                        let encryptedSecretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid, sidPubkey: authentikeySid)
                        
                        self.secretsForBackup.append(encryptedSecretObject)
                        
                        // update exportIndex so if nfc session timeout, we can start where we left
                        DispatchQueue.main.async {
                            self.exportIndex = index+1
                        }
                        
                        print("Exported secret sid: \(encryptedSecretObject.secretHeader.sid) at index: \(index)")
                        //sleep(1)// force multiple nfc session - for debug purpose!
                    }
                    session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
                    
                    DispatchQueue.main.async {
                        self.backupMode = .backupExportReady
                        self.exportIndex = 0
                        print("requestExportSecretsForBackupSession DispatchQueue backupMode: \(self.backupMode)")
                    }
                    print("requestExportSecretsForBackupSession backupMode: \(backupMode)")
                    
                } catch let error {
                    print("requestExportSecretsForBackupSession catch error: \(error)")
                    logEvent(log: LogModel(type: .error, message: "onFetchSecretsForBackup : \(error.localizedDescription)"))
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                }
                
            },
            onFailure: { [weak self] error in
                // these are errors related to NFC communication
                guard let self = self else { return }
                print("requestExportSecretsForBackupSession onFailure: \(error)")
                self.onDisconnection(error: error)
            }
        )// session
        
        print("In while loop backupMode: \(backupMode)")
        session?.start(alertMessage: String(localized: "nfcScanMasterCard")) // TODO: change txt? nfcHoldSatodime
        print("After while loop backupMode: \(backupMode)")
        
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
