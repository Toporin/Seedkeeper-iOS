//
//  CardData.swift
//  Seedkeeper
//
//  Created by Satochip on 01/12/2023.
//

import Foundation
import CoreNFC
import SatochipSwift
import CryptoSwift
import Combine
import SwiftUI
import MnemonicSwift

enum SatocardError: Error {
    case testError(String)
    case randomGeneratorError
    case invalidResponse
}

enum ScannedCardType {
    case master
    case backup
}

class CardState: ObservableObject {
    var dataControllerContext = DataController.shared.container.viewContext
    
    var cmdSet: SatocardCommandSet!
    
    @Published var masterCardStatus: CardStatus?
    @Published var backupCardStatus: CardStatus?
    
    @Published var masterSeedkeeperStatus: SeedkeeperStatus?
    
    @Published var isCardDataAvailable = false
    
    var authentikeyBytes: [UInt8]?
    @Published var certificateDic = [String: String]()
    @Published var certificateCode = PkiReturnCode.unknown
    @Published var errorMessage: String?
    @Published var homeNavigationPath = NavigationPath()
    
    var authentikeyBytesForBackup: [UInt8]? // TODO: rename to backupAuthentikeyBytes
    @Published var certificateDicForBackup = [String: String]() // TODO: remove as unused?
    @Published var certificateCodeForBackup = PkiReturnCode.unknown // TODO: remove as unused?
    
    @Published var masterCardLabel: String = ""
    @Published var backupCardLabel: String = ""
    var cardLabelToSet: String?
    
    var session: SatocardController?
    
    // *********************************************************
    // MARK: Properties for PIN mgmt
    // *********************************************************
    
    var pinCodeToSetup: String?
    private var _pinForMasterCard: String?
    var pinForMasterCard: String? {
        set {
            logger.info("Setting PIN for master", tag: "pinForMasterCard")
            _pinForMasterCard = newValue
            lastTimeForMasterCardPin = Date()
        }
        get {
            if isPinExpired() {
                logger.info("PIN is expired", tag: "pinForMasterCard")
                _pinForMasterCard = nil
                return nil
            } else {
                logger.info("Refreshing PIN expiry", tag: "pinForMasterCard")
                refreshPinExpiry()
                return _pinForMasterCard
            }
        }
    }
    var lastTimeForMasterCardPin: Date?
    
    
    func isPinExpired() -> Bool {
        guard let lastTimeForMasterCardPin = lastTimeForMasterCardPin else {
            return true
        }
        let diff = Calendar.current.dateComponents([.second], from: lastTimeForMasterCardPin, to: Date())
        
        // TODO: add option in settings
        return diff.second! > Constants.pinExpirationInSeconds
    }
    
    func refreshPinExpiry() {
        lastTimeForMasterCardPin = Date()
    }
    
    // *********************************************************
    // MARK: Properties for secret mgmt
    // *********************************************************
    
    @Published var masterSecretHeaders: [SeedkeeperSecretHeader] = []
    
    var currentSecretHeader: SeedkeeperSecretHeader?
    @Published var currentSecretObject: SeedkeeperSecretObject? {
        didSet {
            if let secretBytes = currentSecretObject?.secretBytes,
               let secretType = currentSecretObject?.secretHeader.type,
                let secretSubtype = currentSecretObject?.secretHeader.subtype 
            {
                currentSecretPayload = parseBytesToPayload(secretType: secretType, secretSubtype: secretSubtype, bytes: secretBytes)
                logger.info("Parsed exported secret with type: \(secretType)", tag: "cardState.currentSecretObject")
            } else {
                logger.warning("Failed to parse exported secret!", tag: "cardState.currentSecretObject")
            }
        }
    }
    @Published var currentSecretPayload: Payload?
    
    var secretPayloadToImportOnCard: Payload?
    
    // *********************************************************
    // MARK: Properties for logging
    // *********************************************************
    
    let logger = LoggerService.shared

    // *********************************************************
    // MARK: Properties for backup
    // *********************************************************
    @Published var backupMode: BackupMode = .start {
        didSet {
            logger.info("backup mode is set to : \(backupMode)", tag: "backupMode")
        }
    }
    
    @Published var backupSecretHeaders: [SeedkeeperSecretHeader] = []
    
    var pinForBackupCard: String?
    
    @Published var exportIndex = 0 
    @Published var secretHeadersForBackup: [SeedkeeperSecretHeader] = []
    //var secretsForBackup: [SeedkeeperSecretHeader:SeedkeeperSecretObject] = [:]
    var secretsForBackup: [SeedkeeperSecretObject] = []
    
    @Published var importIndex = 0
    
    var backupError: String = "" // TODO: improve using enum
    
    // *********************************************************
    // MARK: Properties for factory reset
    // *********************************************************
    @Published var resetMode: ResetMode = .start {
        didSet {
            logger.info("reset mode is set to : \(resetMode)", tag: "resetMode")
        }
    }
    @Published var resetRemainingSteps: UInt8 = 0xFF
    
    // *********************************************************
    // MARK: Properties for card logs
    // *********************************************************
    @Published var shouldUpdateCardLogs = true // TODO: flag if cardLogs should be updated 
    @Published var cardLogs: [SeedkeeperLog] = [SeedkeeperLog]()
    @Published var nbTotalLogs: Int = 0
    @Published var nbAvailableLogs: Int = 0
    
    // *********************************************************
    // MARK: scan card to fetch secrets
    // *********************************************************
    
    func scan(for scannedCardType: ScannedCardType){
        
        session = SatocardController(
            onConnect: { [weak self] cardChannel in
                guard let self = self else { return }
                
                logger.info("Start scaning card", tag: "scan")
                
                do{
                    cmdSet = SatocardCommandSet(cardChannel: cardChannel)
                    
                    // get status
                    let (cardStatus, cardType) = try selectAppletAndGetStatus()
                    DispatchQueue.main.async {
                        switch scannedCardType {
                        case .master:
                            self.masterCardStatus = cardStatus
                        case .backup:
                            self.backupCardStatus = cardStatus
                        }
                    }
                    
                    guard let cardStatus = cardStatus else {
                        session?.stop(alertMessage: String(localized: "nfcFailedToConnect"))
                        return
                    }
                    
                    if !cardStatus.setupDone {
                        // Card needs setup
                        session?.stop(alertMessage: String(localized: "nfcCardNeedsSetup"))
                        logger.info("\(String(localized: "nfcCardNeedsSetup"))", tag: "scan")
                        
                        // PIN has already been provided, go to confirmPinCode screen
                        DispatchQueue.main.async {
                            switch scannedCardType {
                            case .master:
                                self.homeNavigationPath.append(NavigationRoutes.confirmPinCode(PinCodeNavigationData(mode: .confirmPinCode, pinCode: self.pinForMasterCard)))
                            case .backup:
                                self.homeNavigationPath.append(NavigationRoutes.confirmPinCode(PinCodeNavigationData(mode: .confirmPinCodeForBackupCard, pinCode: self.pinForBackupCard)))
                            }
                        }
                        
                        return

                    } else {
                        // card needs PIN
                        
                        // TODO: should not be needed since PIN is already requested before scan
                        guard let pin = (scannedCardType == .master) ? pinForMasterCard : pinForBackupCard else {
                            session?.stop(alertMessage: String(localized: "nfcPinCodeIsNotDefined"))
                            logger.info("\(String(localized: "nfcPinCodeIsNotDefined"))", tag: "scan")
                            DispatchQueue.main.async {
                                switch scannedCardType {
                                case .master:
                                    self.homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
                                case .backup:
                                    self.homeNavigationPath.append(NavigationRoutes.pinCode(.continueBackupFlow))
                                }
                            }
                            return
                        }
                        
                        let pinBytes = Array(pin.utf8)
                        do {
                            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
                        } catch CardError.wrongPIN(let retryCounter){
                            DispatchQueue.main.async {
                                switch scannedCardType {
                                case .master:
                                    self.pinForMasterCard = nil
                                case .backup:
                                    self.pinForBackupCard = nil
                                }
                            }
                            
                            if retryCounter == 0 {
                                self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
                                logger.error("\(String(localized: "nfcWrongPinBlocked"))", tag: "scan")
                            } else {
                                self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)")
                                logger.error("\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)", tag: "scan")
                            }
                            return
                        } catch CardError.pinBlocked {
                            DispatchQueue.main.async {
                                switch scannedCardType {
                                case .master:
                                    self.pinForMasterCard = nil
                                case .backup:
                                    self.pinForBackupCard = nil
                                }
                            }
                            self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
                            logger.error("\(String(localized: "nfcWrongPinBlocked"))", tag: "scan")
                            return
                        } catch {
                            DispatchQueue.main.async {
                                switch scannedCardType {
                                case .master:
                                    self.pinForMasterCard = nil
                                case .backup:
                                    self.pinForBackupCard = nil
                                }
                            }
                            self.session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                            logger.error("\(String(localized: "nfcErrorOccured")) : \(error.localizedDescription)", tag: "scan")
                            return
                        }
                    } // if/else
                    
                    // Check authenticity
                    try verifyCardAuthenticity(cardType: scannedCardType)
                    // Fetching authentikey for the first scan and set it in memory
                    try fetchAuthentikey(cardType: scannedCardType)
                        
                    // get seedkeeper status (for v2)
                    if scannedCardType == .master && cardStatus.protocolVersion >= 2 {
                        (_, masterSeedkeeperStatus) = try cmdSet.seedkeeperGetStatus()
                    }
                    
                    // List all secret headers
                    do {
                        let secretHeaders: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
                        DispatchQueue.main.async {
                            switch scannedCardType {
                            case .master:
                                self.masterSecretHeaders = secretHeaders
                            case .backup:
                                self.backupSecretHeaders = secretHeaders
                            }
                        }
                        
                        let fetchedLabel = try cmdSet.cardGetLabel()
                        DispatchQueue.main.async {
                            switch scannedCardType {
                            case .master:
                                self.masterCardLabel = fetchedLabel
                            case .backup:
                                self.backupCardLabel = fetchedLabel
                            }
                        }
                        
                        session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
                        logger.info("\(String(localized: "nfcSecretsListSuccess"))", tag: "scan")
                        
                    } catch let error {
                        logger.error("\(String(localized: "nfcErrorOccured")) : \(error.localizedDescription)", tag: "scan")
                        session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    }
                    
                    DispatchQueue.main.async {
                        switch scannedCardType {
                        case .master:
                            self.isCardDataAvailable = true
                            self.homeNavigationPath = .init()
                        case .backup:
                            self.backupMode = .backupExportFromMaster
                            // get an array of secretHeaders that are in masterSecretHeaders but not in backupSecretHeaders
                            // These are the secrets that must be backuped
                            self.secretHeadersForBackup = self.masterSecretHeaders.filter { headers in !self.backupSecretHeaders.contains(where: { $0.fingerprintBytes == headers.fingerprintBytes }) }
                            self.logger.info("secretHeadersForBackup.count: \(self.secretHeadersForBackup.count)", tag: "requestExportSecretsForBackup")
                            self.homeNavigationPath.append(NavigationRoutes.backup)
                        }
                    }
                    
                } catch let error {
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    logger.error("\(String(localized: "nfcErrorOccured")) : \(error.localizedDescription)", tag: "scan")
                    DispatchQueue.main.async {
                        switch scannedCardType {
                        case .master:
                            self.homeNavigationPath = .init()
                        case .backup:
                            self.homeNavigationPath.append(NavigationRoutes.backup)
                        }
                    }
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
    // MARK: - On disconnection
    // *********************************************************
    func onDisconnection(error: Error) {
        // Handle disconnection
        // TODO: log error
    }
}
