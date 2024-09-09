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
    
    @Published var cardStatus: CardStatus?
    @Published var backupCardStatus: CardStatus?
    
    @Published var isCardDataAvailable = false
    @Published var authentikeyHex = ""
    @Published var certificateDic = [String: String]()
    @Published var certificateCode = PkiReturnCode.unknown
    @Published var errorMessage: String?
    @Published var homeNavigationPath = NavigationPath()
    
    @Published var authentikeyHexForBackup = ""
    @Published var certificateDicForBackup = [String: String]()
    @Published var certificateCodeForBackup = PkiReturnCode.unknown
    
    @Published var cardLabel: String = "n/a"
    var cardLabelToSet: String?
    
    var session: SatocardController?
    var cardController: SatocardController?
    
    private(set) var isPinVerificationSuccess: Bool = false
    
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
    var pinForBackupCard: String?
    
    func isPinExpired() -> Bool {
        guard let lastTimeForMasterCardPin = lastTimeForMasterCardPin else {
            return true
        }
        let diff = Calendar.current.dateComponents([.second], from: lastTimeForMasterCardPin, to: Date())
        return diff.second! > Constants.pinExpirationInSeconds
    }
    
    func refreshPinExpiry() {
        lastTimeForMasterCardPin = Date()
    }
    
    @Published var masterSecretHeaders: [SeedkeeperSecretHeaderDto] = []
    
    @Published var mode: BackupMode = .start {
        didSet {
            print("backup mode is set to : \(mode)")
        }
    }
    
    var secretsForBackup: [SeedkeeperSecretHeaderDto:SeedkeeperSecretObject] = [:]
    
    var currentSecretHeader: SeedkeeperSecretHeaderDto?
    @Published var currentSecretObject: SeedkeeperSecretObject? {
        didSet {
            if currentSecretObject?.secretHeader.type == .password,
               let secretBytes = currentSecretObject?.secretBytes,
               let data = parsePasswordCardData(from: secretBytes) {
                
                    currentPasswordCardData = data
                
            } else if currentSecretObject?.secretHeader.type == .bip39Mnemonic,
                      let secretBytes = currentSecretObject?.secretBytes,
                      let data = parseMnemonicCardData(from: secretBytes) {
                
                currentMnemonicCardData = data
                
            } else if currentSecretObject?.secretHeader.type == .secret2FA,
                      let secretBytes = currentSecretObject?.secretBytes,
                      let data = parse2FACardData(from: secretBytes) {
                
                current2FACardData = data
                
            } else if currentSecretObject?.secretHeader.type == .masterseed,
                      currentSecretObject?.secretHeader.subtype == 0x01,
                      let secretBytes = currentSecretObject?.secretBytes,
                      let data = parseMasterseedMnemonicCardData(bytes: secretBytes) {
                
                currentMasterseedMnemonicCardData = data
                
            } else if currentSecretObject?.secretHeader.type == .masterseed,
                      currentSecretObject?.secretHeader.subtype == 0x00,
                      let secretBytes = currentSecretObject?.secretBytes,
                      let data = parseMasterseedCardData(bytes: secretBytes) {
                
                currentMasterseedCardData = data
                
            } else if currentSecretObject?.secretHeader.type == .electrumMnemonic, let secretBytes = currentSecretObject?.secretBytes, let data = parseElectreumMnemonicCardData(bytes: secretBytes) {
                
                currentElectrumMnemonicCardData = data
                
            } else {
                guard let secretBytes = currentSecretObject?.secretBytes, let data = parseGenericCardData(from: secretBytes) else { return }
                currentGenericCardData = data
             }
        }
    }
    @Published var currentSecretString: String = ""
    @Published var currentPasswordCardData: PasswordCardData?
    @Published var currentMnemonicCardData: MnemonicCardData?
    @Published var current2FACardData: TwoFACardData?
    @Published var currentMasterseedMnemonicCardData: MasterseedMnemonicCardData?
    @Published var currentMasterseedCardData: MasterseedCardData?
    @Published var currentElectrumMnemonicCardData: ElectrumMnemonicCardData?
    @Published var currentGenericCardData: GenericCardData?
    
    var passwordPayloadToImportOnCard: PasswordPayload?
    var mnemonicPayloadToImportOnCard: MnemonicPayload?
    
    var mnemonicManualImportPayload: MnemonicManualImportPayload?
    var passwordManualImportPayload: PasswordManualImportPayload?
    
    func logEvent(log: LogModel) {
        dataControllerContext.saveLogEntry(log: log)
    }

    // *********************************************************
    // MARK: - Master card connection
    // *********************************************************
    func scan() {
        print("CardState scan()")
        DispatchQueue.main.async {
            self.resetState()
        }
        session = SatocardController(onConnect: onConnection, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    func onConnection(cardChannel: CardChannel) -> Void {
        Task {
            do {
                try await handleConnection(cardChannel: cardChannel)
            } catch {
                logEvent(log: LogModel(type: .error, message: "onConnection : \(error.localizedDescription)"))
                
                DispatchQueue.main.async {
                    self.errorMessage = "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)"
                }
                session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
            }
        }
    }
    
    private func handleConnection(cardChannel: CardChannel) async throws {
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        let (statusApdu, cardType) = try await fetchCardStatus()

        cardStatus = try CardStatus(rapdu: statusApdu)
        
        //FaceId integration seems to not be possible for the desired flow, needs further discussion
        
        if let cardStatus = cardStatus, !cardStatus.setupDone {
            // let version = getCardVersionInt(cardStatus: cardStatus)
            // if version <= 0x00010001 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    homeNavigationPath.append(NavigationRoutes.createPinCode(PinCodeNavigationData(mode: .createPinCode, pinCode: nil)))
                }
                session?.stop(alertMessage: String(localized: "nfcCardNeedsSetup"))
                return
            // }
        } else {
            guard let pinForMasterCard = pinForMasterCard else {
                session?.stop(alertMessage: String(localized: "nfcPinCodeIsNotDefined"))
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
                }
                return
            }
            
            let pinBytes = Array(pinForMasterCard.utf8)
            do {
                var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
                self.isPinVerificationSuccess = true
            } catch CardError.wrongPIN(let retryCounter){
                self.pinForMasterCard = nil
                self.isPinVerificationSuccess = false
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
                self.pinForMasterCard = nil
                self.isPinVerificationSuccess = false
                logEvent(log: LogModel(type: .error, message: "onVerifyPin : \(String(localized: "nfcWrongPinBlocked"))"))
                self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
                return
            } catch {
                self.pinForMasterCard = nil
                self.isPinVerificationSuccess = false
                logEvent(log: LogModel(type: .error, message: "onVerifyPin : \(error.localizedDescription)"))
                self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
                return
            }
        }
        
        try await verifyCardAuthenticity(cardType: .master)
        // Fetching authentikey for the first scan and set it in memory
        try await fetchAuthentikey(cardType: .master)
        
        DispatchQueue.main.async {
            self.isCardDataAvailable = true
        }
                
        do {
            let secrets: [SeedkeeperSecretHeader] = try cmdSet.seedkeeperListSecretHeaders()
            self.masterSecretHeaders = secrets.map { SeedkeeperSecretHeaderDto(secretHeader: $0) }
            let fetchedLabel = try cmdSet.cardGetLabel()
            self.cardLabel = !fetchedLabel.isEmpty ? fetchedLabel : "n/a"
            print("Secrets: \(secrets)")
        } catch let error {
            logEvent(log: LogModel(type: .error, message: "onConnection : \(error.localizedDescription)"))
            session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
        }
        
        session?.stop(alertMessage: String(localized: "nfcSecretsListSuccess"))
    }

    // *********************************************************
    // MARK: - On disconnection
    // *********************************************************
    func onDisconnection(error: Error) {
        // Handle disconnection
    }
}
