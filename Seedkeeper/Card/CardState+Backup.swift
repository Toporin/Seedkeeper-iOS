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
        session?.start(alertMessage: String(localized: "nfcScanBackupCardForImport"))
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
            
            try self.importAuthentikeyAsSecret(for: .master)
            
            var onBackupAvailableSecretHeaders: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
            
            for secret in self.secretsForBackup {
                
                let secretFingerPrint = secret.key.fingerprintBytes
                if onBackupAvailableSecretHeaders.contains(where: { $0.fingerprintBytes == secretFingerPrint }) {
                    continue
                }
                
                // TODO: do not import own authentikey! (or may be just do not import authentikey??)
                
                do {
                    var secretBuffer = secret // TODO: why use secretBuffer
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
    // MARK: Export secrets from master card for backup
    // *********************************************************
    
    func requestExportSecretsForBackup(){
        
        session = SatocardController(
            onConnect: { [weak self] cardChannel in
                guard let self = self else { return }

                guard let pinForMasterCard = pinForMasterCard else {
                    session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
                    homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
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
                    
                    //for secretHeader in secretHeaders {
                    //for (index, secretHeader) in secretHeaders.enumerated() {
                    for index in backupIndex ..< secretHeaders.count {
                        // TODO: skip authentikeys?
                        let secretHeader = secretHeaders[index]
                        
                        //var secretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid)
                        
                        let encryptedSecretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid, sidPubkey: authentikeySid)// TODO: check that backupAuthentiKeySid is correct, or (better) refactor
                        
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
    
    // multisession while loop in 1 function
//    func requestExportSecretsForBackup(){
//        
//        var exportBusy = false
//        var exportDone = false
//        
//        
//        session = SatocardController(
//            onConnect: { [weak self] cardChannel in
//                guard let self = self else {
////                    self?.session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined")) // TODO: required?
////                    self?.backupBusy = false
//                    return
//                }
//                
//                //self.backupBusy = true //infinite loop
//                exportBusy = true
//                
//                guard let pinForMasterCard = pinForMasterCard else {
//                    session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
//                    exportBusy = false
//                    homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
//                    return
//                }
//                
//                cmdSet = SatocardCommandSet(cardChannel: cardChannel)
//                
//                do {
//                    let pinBytes = Array(pinForMasterCard.utf8)
//                    var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
//                    
//                    let isAuthentikeyValid = try isAuthentikeyValid(for: .master)
//                    if !isAuthentikeyValid {
//                        logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
//                        session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
//                        return
//                    }
//                    
//                    // get the list of secrets headers
//                    // TODO: reuse list already fetched during scan()?
//                    // TODO: use self.masterSecretHeaders
//                    let secretHeaders: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
//                    
//                    // check whether the backup authentikey is already present in card
//                    let authentikeySecretBytes = [UInt8(authentikeyBytesForBackup!.count)] + authentikeyBytesForBackup!
//                    let authentikeyFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: authentikeySecretBytes)
//                    var authentikeySid = 0
//                    if let authentikeyHeader = secretHeaders.first(where: {$0.fingerprintBytes == authentikeyFingerprintBytes}) {
//                        // the backup authentikey is already store in the card, get its sid
//                        authentikeySid = authentikeyHeader.sid
//                        print("Backup authentikey is already present in card with sid: \(authentikeySid)")
//                    } else {
//                        // the backup authentikey could not be found, so we import it (required to export encrypted secrets)
//                        authentikeySid = try self.importAuthentikeyAsSecret(for: .backup)
//                        print("Backup authentikey imported in card with sid: \(authentikeySid)")
//                    }
//                    
//                    var fetchedSecretsFromCard: [SeedkeeperSecretHeader:SeedkeeperSecretObject] = [:]
//                    
//                    //for secretHeader in secretHeaders {
//                    //for (index, secretHeader) in secretHeaders.enumerated() {
//                    for index in backupIndex ..< secretHeaders.count {
//                        // TODO: skip authentikeys?
//                        let secretHeader = secretHeaders[index]
//                        
//                        //var secretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid)
//                        
//                        let encryptedSecretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid, sidPubkey: authentikeySid)// TODO: check that backupAuthentiKeySid is correct, or (better) refactor
//                        
//                        fetchedSecretsFromCard[SeedkeeperSecretHeader(secretHeader: secretHeader)] = encryptedSecretObject
//                        
//                        backupIndex = index+1
//                        print("Exported secret sid: \(encryptedSecretObject.secretHeader.sid) at index: \(index)")
//                        sleep(1)// for debug purpose!
//                    }
//                    session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
//                    
//                    self.secretsForBackup = fetchedSecretsFromCard
//                    
//                    print("secretsToImport : \(fetchedSecretsFromCard)")
//                    print("requestExportSecretsForBackupSession backupMode before update: \(backupMode)")
//                    //backupMode = .backupExportReady
//                    exportDone = true
//                    print("requestExportSecretsForBackupSession backupMode after update: \(backupMode)")
////                    DispatchQueue.main.sync {
////                        self.backupMode = .backupExportReady
////                        print("requestExportSecretsForBackupSession DispatchQueue backupMode: \(self.backupMode)")
////                    }
////                    DispatchQueue.main.async { [weak self] in
////                        guard let self = self else {
////                            print("requestExportSecretsForBackupSession DispatchQueue RETURN")
////                            return
////                        }
////                        backupMode = .backupExportReady
////                        print("requestExportSecretsForBackupSession DispatchQueue backupMode: \(backupMode)")
////                    }
//                    DispatchQueue.main.async {
//                        self.backupMode = .backupExportReady
//                        print("requestExportSecretsForBackupSession DispatchQueue backupMode: \(self.backupMode)")
//                    }
//                    print("requestExportSecretsForBackupSession backupMode: \(backupMode)")
//                    
//                    //session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
//                    exportBusy = false
//                } catch let error {
//                    print("requestExportSecretsForBackupSession catch error: \(error)")
//                    logEvent(log: LogModel(type: .error, message: "onFetchSecretsForBackup : \(error.localizedDescription)"))
//                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//                    exportBusy = false
//                }
//                
//            },
//            onFailure: { [weak self] error in
//                // these are errors related to NFC communication
//                guard let self = self else { return }
//                print("requestExportSecretsForBackupSession onFailure: \(error)")
//                self.onDisconnection(error: error)
//                exportBusy = false
//            }
//        )// session
//        
////        print("In while loop backupMode: \(backupMode)")
////        session?.start(alertMessage: String(localized: "nfcScanMasterCard")) // TODO: change txt? nfcHoldSatodime
////        print("After while loop backupMode: \(backupMode)")
//        
//        //while (backupMode != .backupExportReady){
//        while (!exportDone){
//            if (!exportBusy){
//                print("in requestExportSecretsForBackup while START")
//                session?.start(alertMessage: String(localized: "nfcScanMasterCard")) // TODO: change txt? nfcHoldSatodime
//                print("in requestExportSecretsForBackup while END")
//            }
//            sleep(1)
//        }
//        print("requestExportSecretsForBackup Function END")
//    }
    
    
//    func requestExportSecretsForBackup(){
//        backupBusy = false
//        exportDone = false
//        //while (backupMode != .backupExportReady){
//        while (!exportDone){
//            if (!backupBusy){
//                print("in requestExportSecretsForBackup while START")
//                requestExportSecretsForBackupSession()
//                print("in requestExportSecretsForBackup while END")
//            }
//            sleep(1)
//        }
//        print("requestExportSecretsForBackup Function END")
//    }
//    
//    func requestExportSecretsForBackupSession(){
//        // TODO: manage multiple nfc session in case of time-out...
//        
//        // manage multi-session
//        //var backupIndex = 0
//        //var backupBusy = false //while loop finish immediately
//        //var exportDone = false
//        
//        session = SatocardController(
//            onConnect: { [weak self] cardChannel in
//                guard let self = self else {
////                    self?.session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined")) // TODO: required?
////                    self?.backupBusy = false
//                    return
//                }
//                
//                //self.backupBusy = true //infinite loop
//                self.backupBusy = true
//                
//                guard let pinForMasterCard = pinForMasterCard else {
//                    session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
//                    self.backupBusy = false
//                    homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
//                    return
//                }
//                
//                cmdSet = SatocardCommandSet(cardChannel: cardChannel)
//                
//                do {
//                    let pinBytes = Array(pinForMasterCard.utf8)
//                    var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
//                    
//                    let isAuthentikeyValid = try isAuthentikeyValid(for: .master)
//                    if !isAuthentikeyValid {
//                        logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
//                        session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
//                        return
//                    }
//                    
//                    // get the list of secrets headers
//                    // TODO: reuse list already fetched during scan()?
//                    // TODO: use self.masterSecretHeaders
//                    let secretHeaders: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
//                    
//                    // check whether the backup authentikey is already present in card
//                    let authentikeySecretBytes = [UInt8(authentikeyBytesForBackup!.count)] + authentikeyBytesForBackup!
//                    let authentikeyFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: authentikeySecretBytes)
//                    var authentikeySid = 0
//                    if let authentikeyHeader = secretHeaders.first(where: {$0.fingerprintBytes == authentikeyFingerprintBytes}) {
//                        // the backup authentikey is already store in the card, get its sid
//                        authentikeySid = authentikeyHeader.sid
//                        print("Backup authentikey is already present in card with sid: \(authentikeySid)")
//                    } else {
//                        // the backup authentikey could not be found, so we import it (required to export encrypted secrets)
//                        authentikeySid = try self.importAuthentikeyAsSecret(for: .backup)
//                        print("Backup authentikey imported in card with sid: \(authentikeySid)")
//                    }
//                    
//                    var fetchedSecretsFromCard: [SeedkeeperSecretHeader:SeedkeeperSecretObject] = [:]
//                    
//                    //for secretHeader in secretHeaders {
//                    //for (index, secretHeader) in secretHeaders.enumerated() {
//                    for index in backupIndex ..< secretHeaders.count {
//                        // TODO: skip authentikeys?
//                        let secretHeader = secretHeaders[index]
//                        
//                        //var secretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid)
//                        
//                        let encryptedSecretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid, sidPubkey: authentikeySid)// TODO: check that backupAuthentiKeySid is correct, or (better) refactor
//                        
//                        fetchedSecretsFromCard[SeedkeeperSecretHeader(secretHeader: secretHeader)] = encryptedSecretObject
//                        
//                        backupIndex = index+1
//                        print("Exported secret sid: \(encryptedSecretObject.secretHeader.sid) at index: \(index)")
//                        sleep(1)// for debug purpose!
//                    }
//                    session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
//                    
//                    self.secretsForBackup = fetchedSecretsFromCard
//                    
//                    print("secretsToImport : \(fetchedSecretsFromCard)")
//                    print("requestExportSecretsForBackupSession backupMode before update: \(backupMode)")
//                    //backupMode = .backupExportReady
//                    exportDone = true
//                    print("requestExportSecretsForBackupSession backupMode after update: \(backupMode)")
////                    DispatchQueue.main.sync {
////                        self.backupMode = .backupExportReady
////                        print("requestExportSecretsForBackupSession DispatchQueue backupMode: \(self.backupMode)")
////                    }
////                    DispatchQueue.main.async { [weak self] in
////                        guard let self = self else {
////                            print("requestExportSecretsForBackupSession DispatchQueue RETURN")
////                            return
////                        }
////                        backupMode = .backupExportReady
////                        print("requestExportSecretsForBackupSession DispatchQueue backupMode: \(backupMode)")
////                    }
//                    DispatchQueue.main.async {
//                        self.backupMode = .backupExportReady
//                        print("requestExportSecretsForBackupSession DispatchQueue backupMode: \(self.backupMode)")
//                    }
//                    print("requestExportSecretsForBackupSession backupMode: \(backupMode)")
//                    
//                    //session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
//                    backupBusy = false
//                } catch let error {
//                    print("requestExportSecretsForBackupSession catch error: \(error)")
//                    logEvent(log: LogModel(type: .error, message: "onFetchSecretsForBackup : \(error.localizedDescription)"))
//                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//                    backupBusy = false
//                }
//                
//            },
//            onFailure: { [weak self] error in
//                // these are errors related to NFC communication
//                guard let self = self else { return }
//                print("requestExportSecretsForBackupSession onFailure: \(error)")
//                self.onDisconnection(error: error)
//                backupBusy = false
//            }
//        )// session
//        
//        print("In while loop backupMode: \(backupMode)")
//        session?.start(alertMessage: String(localized: "nfcScanMasterCard")) // TODO: change txt? nfcHoldSatodime
//        print("After while loop backupMode: \(backupMode)")
//        
////        backupBusy = false
////        while (!exportDone){
////            if (!backupBusy){
////                print("in requestExportSecretsForBackup while START")
////                session?.start(alertMessage: String(localized: "nfcScanMasterCard")) // TODO: change txt? nfcHoldSatodime
////                print("in requestExportSecretsForBackup while END")
////            }
////            sleep(1)
////        }
////        print("requestExportSecretsForBackup Function END")
//        
//        
//        //session?.start(alertMessage: String(localized: "nfcScanMasterCard")) // TODO: change txt? nfcHoldSatodime
//    }
    
    // MARK: Old code to remove
    
    // TODO: rename to exportSecretsForBackup
//    func requestFetchSecretsForBackup() {
//        session = SatocardController(onConnect: onFetchSecretsForBackup, onFailure: onDisconnection)
//        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
//    }
//    
//    func onFetchSecretsForBackup(cardChannel: CardChannel) -> Void {
//        guard let pinForMasterCard = pinForMasterCard else {
//            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
//            homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
//            return
//        }
//        
//        let pinBytes = Array(pinForMasterCard.utf8)
//        
//        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
//        
//        do {
//            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
//            
//            var isAuthentikeyValid = try isAuthentikeyValid(for: .master)
//            
//            if !isAuthentikeyValid {
//                logEvent(log: LogModel(type: .error, message: "onImportSecretsToBackupCard : invalid AuthentiKey"))
//                session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
//                return
//            }
//            
//            self.importAuthentikeyAsSecret(for: .backup)
//            
//            var secretHeaders: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
//            
//            var fetchedSecretsFromCard: [SeedkeeperSecretHeader:SeedkeeperSecretObject] = [:]
//            
//            for secretHeader in secretHeaders {
//                var secretObject = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid)
//                
//                var encryptedResult = try cmdSet.seedkeeperExportSecret(sid: secretHeader.sid, sidPubkey: self.backupAuthentiKeySid!)
//                
//                fetchedSecretsFromCard[SeedkeeperSecretHeader(secretHeader: secretHeader)] = encryptedResult
//            }
//            
//            self.secretsForBackup = fetchedSecretsFromCard
//            
//            print("secretsToImport : \(fetchedSecretsFromCard)")
//            mode = .backupExportReady
//            session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
//        } catch let error {
//            logEvent(log: LogModel(type: .error, message: "onFetchSecretsForBackup : \(error.localizedDescription)"))
//            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//        }
//    }
    
    func importAuthentikeyAsSecret(for cardType: ScannedCardType) throws -> Int {
//        do {
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
            if cardType == .master {
                self.masterAuthentiKeyBytes = authentikeyBytes
                self.masterAuthentiKeySid = authentikeySid
                self.masterAuthentiKeyFingerprintBytes = fingerprintBytes
            } else if cardType == .backup {
                self.backupAuthentiKeyBytes = authentikeyBytes
                self.backupAuthentiKeySid = authentikeySid
                self.backupAuthentiKeyFingerprintBytes = fingerprintBytes
            }
            return authentikeySid
            
//        } catch {
//            logEvent(log: LogModel(type: .error, message: "importAuthentikeyAsSecret : \(error.localizedDescription)"))
//            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//            return 0 //TODO: something
//        }
    }
    
    // *********************************************************
    // MARK: - Backup card - connection
    // *********************************************************
    
    //TODO: merge with scan()
    func scanBackupCard() {
        print("CardState scanBackupCard()")
        session = SatocardController(onConnect: onConnectionForBackupCard, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanBackupCard"))
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
        
        let status = try CardStatus(rapdu: statusApdu)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            backupCardStatus = status
        }
        
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
                logEvent(log: LogModel(type: .error, message: "handleConnectionForBackupCard : \(error.localizedDescription)"))
                self.session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                return
            }
        }
        
        try await verifyCardAuthenticity(cardType: .backup)
        try await fetchAuthentikey(cardType: .backup)
                
        // self.importAuthentikeyAsSecret(for: .backup)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.backupMode = .backupImport
        }
        
        session?.stop(alertMessage: String(localized: "nfcBackupCardPairedSuccess"))
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
        backupMode = .start
        if clearPin {
            pinForBackupCard = nil
        }
    }
}
