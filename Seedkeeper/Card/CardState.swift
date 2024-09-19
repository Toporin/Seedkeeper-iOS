//
//  CardData.swift
//  Satodime
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
    
    @Published var isCardDataAvailable = false
    @Published var authentikeyHex = ""
    var authentikeyBytes: [UInt8]?
    @Published var certificateDic = [String: String]()
    @Published var certificateCode = PkiReturnCode.unknown
    @Published var errorMessage: String?
    @Published var homeNavigationPath = NavigationPath()
    
    @Published var authentikeyHexForBackup = ""
    var authentikeyBytesForBackup: [UInt8]?
    @Published var certificateDicForBackup = [String: String]()
    @Published var certificateCodeForBackup = PkiReturnCode.unknown
    
    @Published var masterCardLabel: String = "n/a"
    @Published var backupCardLabel: String = ""
    var cardLabelToSet: String?
    
    var session: SatocardController?
    
    // *********************************************************
    // MARK: Properties for PIN mgmt
    // *********************************************************
    
    //private(set) var isPinVerificationSuccess: Bool = false // TODO: remove
    
    var pinCodeToSetup: String?
    private var _pinForMasterCard: String?
    var pinForMasterCard: String? {
        set {
            print("(set) - Setting pin for master")
            _pinForMasterCard = newValue
            lastTimeForMasterCardPin = Date()
        }
        get {
            if isPinExpired() {
                print("(get) - Pin is expired!")
                _pinForMasterCard = nil
                return nil
            } else {
                print("(get) - refreshing pin expiry")
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
            }
        }
    }
    @Published var currentSecretPayload: Payload?
    
    var secretPayloadToImportOnCard: Payload?
    
    func logEvent(log: LogModel) {
        // TODO: do not persist logs?
        dataControllerContext.saveLogEntry(log: log)
    }

    // *********************************************************
    // MARK: Properties for backup
    // *********************************************************
    @Published var backupMode: BackupMode = .start {
        didSet {
            print("backup mode is set to : \(backupMode)")
        }
    }
    
    @Published var backupSecretHeaders: [SeedkeeperSecretHeader] = []
    
    var pinForBackupCard: String?
    
    @Published var backupIndex = 0
//    var backupBusy = false
//    var exportDone = false
    var secretsForBackup: [SeedkeeperSecretHeader:SeedkeeperSecretObject] = [:]
    
    var backupAuthentiKeySid: Int?
    var backupAuthentiKeyFingerprintBytes: [UInt8]?
    var backupAuthentiKeyBytes: [UInt8]?
    
    var masterAuthentiKeySid: Int?
    var masterAuthentiKeyFingerprintBytes: [UInt8]?
    var masterAuthentiKeyBytes: [UInt8]?
    
    // *********************************************************
    // MARK: scan card to fetch secrets
    // *********************************************************
    
    func scan(for scannedCardType: ScannedCardType){
        
        session = SatocardController(
            onConnect: { [weak self] cardChannel in
                guard let self = self else { return }
                
                do{
                    cmdSet = SatocardCommandSet(cardChannel: cardChannel)
                    
                    // get status
                    let (cardStatus, cardType) = try fetchCardStatus()
                    DispatchQueue.main.async {
                        switch scannedCardType {
                        case .master:
                            self.masterCardStatus = cardStatus
                        case .backup:
                            self.backupCardStatus = cardStatus
                        }
                    }
                    
                    if !cardStatus.setupDone {
                        // Card needs setup
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            homeNavigationPath.append(NavigationRoutes.createPinCode(PinCodeNavigationData(mode: .createPinCode, pinCode: nil)))
                        }
                        session?.stop(alertMessage: String(localized: "nfcCardNeedsSetup"))
                        return

                    } else {
                        // card needs PIN
                        guard let pin = (scannedCardType == .master) ? pinForMasterCard : pinForBackupCard else {
                            session?.stop(alertMessage: String(localized: "nfcPinCodeIsNotDefined"))
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
//                            self.isPinVerificationSuccess = true // TODO: remove
                        } catch CardError.wrongPIN(let retryCounter){
                            DispatchQueue.main.async {
                                switch scannedCardType {
                                case .master:
                                    self.pinForMasterCard = nil
                                case .backup:
                                    self.pinForBackupCard = nil
                                }
                            }
                            
//                            self.isPinVerificationSuccess = false
                            logEvent(log: LogModel(type: .error, message: "onVerifyPin : \("\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)"))"))
                            if retryCounter == 0 {
                                logEvent(log: LogModel(type: .error, message: "onVerifyPin : \(String(localized: "nfcWrongPinBlocked"))"))
                                self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
                            } else {
                                self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)")
                            }
                            return
                            // TODO: NB: CardError.pinBlocked is not returned when pin is blocked on card
                        } catch CardError.pinBlocked {
                            DispatchQueue.main.async {
                                switch scannedCardType {
                                case .master:
                                    self.pinForMasterCard = nil
                                case .backup:
                                    self.pinForBackupCard = nil
                                }
                            }
//                            self.isPinVerificationSuccess = false
                            logEvent(log: LogModel(type: .error, message: "onVerifyPin : \(String(localized: "nfcWrongPinBlocked"))"))
                            self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
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
//                            self.isPinVerificationSuccess = false
                            logEvent(log: LogModel(type: .error, message: "handleConnection : \(error.localizedDescription)"))
                            self.session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                            return
                        }
                    } // if/else
                    
                    // Check authenticity
                    try verifyCardAuthenticity(cardType: scannedCardType)
                    // Fetching authentikey for the first scan and set it in memory
                    try fetchAuthentikey(cardType: scannedCardType)
                        
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
                                self.masterCardLabel = !fetchedLabel.isEmpty ? fetchedLabel : "n/a"
                            case .backup:
                                self.backupCardLabel = !fetchedLabel.isEmpty ? fetchedLabel : "n/a"
                            }
                        }
                        
                        print("Secret headers: \(secretHeaders)")
                    } catch let error {
                        logEvent(log: LogModel(type: .error, message: "handleConnection : \(error.localizedDescription)"))
                        session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    }
                    session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))

                    DispatchQueue.main.async {
                        switch scannedCardType {
                        case .master:
                            self.isCardDataAvailable = true
                        case .backup:
                            self.backupMode = .backupImport
                        }
                    }
                    
                } catch let error {
                    print("onImportSecret ERROR \(error.localizedDescription)")
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    logEvent(log: LogModel(type: .error, message: "onAddPasswordSecret : \(error.localizedDescription)"))
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
    
    
    ////
//    func scan() {
//        print("CardState scan()")
//        DispatchQueue.main.async {
//            self.resetState()
//        }
//        session = SatocardController(onConnect: onConnection, onFailure: onDisconnection)
//        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
//    }
//    
//    func onConnection(cardChannel: CardChannel) -> Void {
//        Task {
//            do {
//                try await handleConnection(cardChannel: cardChannel)
//            } catch {
//                logEvent(log: LogModel(type: .error, message: "onConnection : \(error.localizedDescription)"))
//                
//                DispatchQueue.main.async {
//                    self.errorMessage = "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)"
//                }
//                session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    private func handleConnection(cardChannel: CardChannel) async throws {
//        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
//        
//        let (statusApdu, cardType) = try await fetchCardStatus()
//
//        cardStatus = try CardStatus(rapdu: statusApdu)
//        
//        //FaceId integration seems to not be possible for the desired flow, needs further discussion
//        
//        if let cardStatus = cardStatus, !cardStatus.setupDone {
//            // Card needs setup
//            
//            // let version = getCardVersionInt(cardStatus: cardStatus)
//            // if version <= 0x00010001 {
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//                    homeNavigationPath.append(NavigationRoutes.createPinCode(PinCodeNavigationData(mode: .createPinCode, pinCode: nil)))
//                }
//                session?.stop(alertMessage: String(localized: "nfcCardNeedsSetup"))
//                return
//            // }
//        } else {
//            // card needs PIN
//            
//            guard let pinForMasterCard = pinForMasterCard else {
//                session?.stop(alertMessage: String(localized: "nfcPinCodeIsNotDefined"))
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//                    homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
//                }
//                return
//            }
//            
//            let pinBytes = Array(pinForMasterCard.utf8)
//            do {
//                var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
//                self.isPinVerificationSuccess = true
//            } catch CardError.wrongPIN(let retryCounter){
//                self.pinForMasterCard = nil
//                self.isPinVerificationSuccess = false
//                logEvent(log: LogModel(type: .error, message: "onVerifyPin : \("\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)"))"))
//                if retryCounter == 0 {
//                    logEvent(log: LogModel(type: .error, message: "onVerifyPin : \(String(localized: "nfcWrongPinBlocked"))"))
//                    self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
//                } else {
//                    self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)")
//                }
//                return
//                // TODO: NB: CardError.pinBlocked is not returned when pin is blocked on card
//            } catch CardError.pinBlocked {
//                self.pinForMasterCard = nil
//                self.isPinVerificationSuccess = false
//                logEvent(log: LogModel(type: .error, message: "onVerifyPin : \(String(localized: "nfcWrongPinBlocked"))"))
//                self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
//                return
//            } catch {
//                self.pinForMasterCard = nil
//                self.isPinVerificationSuccess = false
//                logEvent(log: LogModel(type: .error, message: "handleConnection : \(error.localizedDescription)"))
//                self.session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//                return
//            }
//        }
//        
//        // Check authenticity
//        try await verifyCardAuthenticity(cardType: .master)
//        // Fetching authentikey for the first scan and set it in memory
//        try await fetchAuthentikey(cardType: .master)
//        
//        DispatchQueue.main.async {
//            self.isCardDataAvailable = true
//        }
//            
//        // List all secret headers
//        do {
//            let secrets: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
//            self.masterSecretHeaders = secrets //.map { SeedkeeperSecretHeader(secretHeader: $0) }
//            let fetchedLabel = try cmdSet.cardGetLabel()
//            self.cardLabel = !fetchedLabel.isEmpty ? fetchedLabel : "n/a"
//            print("Secrets: \(secrets)")
//        } catch let error {
//            logEvent(log: LogModel(type: .error, message: "handleConnection : \(error.localizedDescription)"))
//            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//        }
//        
//        session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
//    }

    
    
//    func scan() {
//        print("CardState scan()")
//        DispatchQueue.main.async {
//            self.resetState()
//        }
//        session = SatocardController(onConnect: onConnection, onFailure: onDisconnection)
//        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
//    }
//    
//    func onConnection(cardChannel: CardChannel) -> Void {
//        Task {
//            do {
//                try await handleConnection(cardChannel: cardChannel)
//            } catch {
//                logEvent(log: LogModel(type: .error, message: "onConnection : \(error.localizedDescription)"))
//                
//                DispatchQueue.main.async {
//                    self.errorMessage = "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)"
//                }
//                session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    private func handleConnection(cardChannel: CardChannel) async throws {
//        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
//        
//        let (statusApdu, cardType) = try await fetchCardStatus()
//
//        cardStatus = try CardStatus(rapdu: statusApdu)
//        
//        //FaceId integration seems to not be possible for the desired flow, needs further discussion
//        
//        if let cardStatus = cardStatus, !cardStatus.setupDone {
//            // Card needs setup
//            
//            // let version = getCardVersionInt(cardStatus: cardStatus)
//            // if version <= 0x00010001 {
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//                    homeNavigationPath.append(NavigationRoutes.createPinCode(PinCodeNavigationData(mode: .createPinCode, pinCode: nil)))
//                }
//                session?.stop(alertMessage: String(localized: "nfcCardNeedsSetup"))
//                return
//            // }
//        } else {
//            // card needs PIN
//            
//            guard let pinForMasterCard = pinForMasterCard else {
//                session?.stop(alertMessage: String(localized: "nfcPinCodeIsNotDefined"))
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//                    homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
//                }
//                return
//            }
//            
//            let pinBytes = Array(pinForMasterCard.utf8)
//            do {
//                var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
//                self.isPinVerificationSuccess = true
//            } catch CardError.wrongPIN(let retryCounter){
//                self.pinForMasterCard = nil
//                self.isPinVerificationSuccess = false
//                logEvent(log: LogModel(type: .error, message: "onVerifyPin : \("\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)"))"))
//                if retryCounter == 0 {
//                    logEvent(log: LogModel(type: .error, message: "onVerifyPin : \(String(localized: "nfcWrongPinBlocked"))"))
//                    self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
//                } else {
//                    self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)")
//                }
//                return
//                // TODO: NB: CardError.pinBlocked is not returned when pin is blocked on card
//            } catch CardError.pinBlocked {
//                self.pinForMasterCard = nil
//                self.isPinVerificationSuccess = false
//                logEvent(log: LogModel(type: .error, message: "onVerifyPin : \(String(localized: "nfcWrongPinBlocked"))"))
//                self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
//                return
//            } catch {
//                self.pinForMasterCard = nil
//                self.isPinVerificationSuccess = false
//                logEvent(log: LogModel(type: .error, message: "handleConnection : \(error.localizedDescription)"))
//                self.session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//                return
//            }
//        }
//        
//        // Check authenticity
//        try await verifyCardAuthenticity(cardType: .master)
//        // Fetching authentikey for the first scan and set it in memory
//        try await fetchAuthentikey(cardType: .master)
//        
//        DispatchQueue.main.async {
//            self.isCardDataAvailable = true
//        }
//            
//        // List all secret headers
//        do {
//            let secrets: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
//            self.masterSecretHeaders = secrets //.map { SeedkeeperSecretHeader(secretHeader: $0) }
//            let fetchedLabel = try cmdSet.cardGetLabel()
//            self.cardLabel = !fetchedLabel.isEmpty ? fetchedLabel : "n/a"
//            print("Secrets: \(secrets)")
//        } catch let error {
//            logEvent(log: LogModel(type: .error, message: "handleConnection : \(error.localizedDescription)"))
//            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
//        }
//        
//        session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
//    }

    // *********************************************************
    // MARK: - On disconnection
    // *********************************************************
    func onDisconnection(error: Error) {
        // Handle disconnection
        // TODO: log error
    }
}
