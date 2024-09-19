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
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
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
            
            for secret in self.secretsForBackup {
         
                do {
                    try cmdSet.seedkeeperImportSecret(secretObject: secret.value, sidPubkey: authentikeySid)
                    // TODO: check rapdu
                    
                } catch {
                    // TODO: add to report
                    logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : \(error.localizedDescription)"))
                    return
                }
            }
            
            session?.stop(alertMessage: String(localized: "nfcBackupSuccess"))
            
            DispatchQueue.main.async {
                self.homeNavigationPath.append(NavigationRoutes.backupSuccess)
            }
            
            
        } catch let error {
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
                    var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
                    
                    let isAuthentikeyValid = try isAuthentikeyValid(for: .master)
                    if !isAuthentikeyValid {
                        logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
                        session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                        return
                    }
                    
                    // get the list of secrets headers
                    //let secretHeaders: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
                    let secretHeaders: [SeedkeeperSecretHeader] = masterSecretHeaders
                    
                    // check whether the backup authentikey is already present in card
                    let authentikeySecretBytes = [UInt8(authentikeyBytesForBackup!.count)] + authentikeyBytesForBackup!
                    let authentikeyFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: authentikeySecretBytes)
                    var authentikeySid = 0
                    if let authentikeyHeader = secretHeaders.first(where: {$0.fingerprintBytes == authentikeyFingerprintBytes}) {
                        // the backup authentikey is already store in the card, get its sid
                        authentikeySid = authentikeyHeader.sid
                        print("Backup authentikey is already present in card with sid: \(authentikeySid)")
                    } else {
                        // the backup authentikey could not be found, so we import it (required to export encrypted secrets)
                        authentikeySid = try self.importAuthentikeyAsSecret(for: .backup)
                        print("Backup authentikey imported in card with sid: \(authentikeySid)")
                    }
                    
                    var fetchedSecretsFromCard: [SeedkeeperSecretHeader:SeedkeeperSecretObject] = [:]
                    
                    for index in backupIndex ..< secretHeaders.count {
                        let secretHeader = secretHeaders[index]
                        
                        // check secret type: skip backup authentikey
                        // TODO: perform these checks before initiating scan session for performance?
                        // TODO: skip all pubkeys or only the backup authentikey?
                        if secretHeader.type == .pubkey {
                            // TODO: log
                            continue
                        }
                        
                        // Check if secret is already saved in backup card (based on fingerprint)
                        if backupSecretHeaders.contains(where: {$0.fingerprintBytes == secretHeader.fingerprintBytes}) {
                            // TODO: create a report to show to user
                            print("Secret: \(secretHeader.label) is already saved in backup card!")
                            continue
                        }
                        
                        let encryptedSecretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid, sidPubkey: authentikeySid)
                        
                        fetchedSecretsFromCard[secretHeader] = encryptedSecretObject
                        
                        backupIndex = index+1
                        print("Exported secret sid: \(encryptedSecretObject.secretHeader.sid) at index: \(index)")
                        sleep(1)// force multiple nfc session - for debug purpose!
                    }
                    session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
                    
                    self.secretsForBackup = fetchedSecretsFromCard
                    print("secretsToImport : \(fetchedSecretsFromCard)")
                    
                    DispatchQueue.main.async {
                        self.backupMode = .backupExportReady
                        // self.backupIndex = 0 // todo: reset index for next backup
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
        
        // TODO: remove?
//        if cardType == .master {
//            self.masterAuthentiKeyBytes = authentikeyBytes
//            self.masterAuthentiKeySid = authentikeySid
//            self.masterAuthentiKeyFingerprintBytes = fingerprintBytes
//        } else if cardType == .backup {
//            self.backupAuthentiKeyBytes = authentikeyBytes
//            self.backupAuthentiKeySid = authentikeySid
//            self.backupAuthentiKeyFingerprintBytes = fingerprintBytes
//        }
        
        return authentikeySid
    }
    
    // *********************************************************
    // MARK: - Backup card - connection
    // *********************************************************
    
    func resetStateForBackupCard(clearPin: Bool = false) {
        certificateCodeForBackup = .unknown
//        authentikeyHexForBackup = ""
        authentikeyBytes = nil
        authentikeyBytesForBackup = nil
        
//        masterAuthentiKeySid = nil
//        masterAuthentiKeyBytes = nil
//        masterAuthentiKeyFingerprintBytes = nil
//        
//        backupAuthentiKeySid = nil
//        backupAuthentiKeyBytes = nil
//        backupAuthentiKeyFingerprintBytes = nil
        
        secretsForBackup = [:]
        backupMode = .start
        if clearPin {
            pinForBackupCard = nil
        }
    }
}
