//
//  CardState+Pin.swift
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
    // MARK: - Update card pin code
    // *********************************************************
    func requestUpdatePinOnCard(newPin: String) {
        pinCodeToSetup = newPin
        session = SatocardController(onConnect: onUpdatePinCode, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    private func onUpdatePinCode(cardChannel: CardChannel) -> Void {
        guard let pinForMasterCard = self.pinForMasterCard, let pinCodeToSetup = self.pinCodeToSetup else {
            session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
            logger.info(String(localized: "nfcPinCodeIsNotDefined"), tag: "onUpdatePinCode")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
            }
            return
        }
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            // check that card authentikey matches the cached one
            if let authentikeyBytes = authentikeyBytes {
                let (_, possibleAuthentikeys) = try cmdSet.cardInitiateSecureChannel()
                guard possibleAuthentikeys.contains(authentikeyBytes) else {
                    session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                    logger.error("\(String(localized: "nfcAuthentikeyError"))", tag: "onUpdatePinCode")
                    return
                }
            }
            
            let pinBytes = Array(pinForMasterCard.utf8)
            _ = try cmdSet.cardVerifyPIN(pin: pinBytes)
            
            let pinBytesNew = Array(pinCodeToSetup.utf8)
            _ = try cmdSet.cardChangePIN(oldPin: pinBytes, newPin: pinBytesNew)
            
            session?.stop(alertMessage: String(localized: "nfcPinCodeUpdateSuccess"))
            logger.info(String(localized: "nfcPinCodeUpdateSuccess"), tag: "onUpdatePinCode")
            
            DispatchQueue.main.async {
                self.pinForMasterCard = pinCodeToSetup
                self.pinCodeToSetup = nil
                self.homeNavigationPath = .init()
            }
            
        } catch CardError.wrongPIN(let retryCounter) {
            self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)")
            logger.error("\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)", tag: "onUpdatePinCode")
            DispatchQueue.main.async {
                self.pinForMasterCard = nil
            }
        } catch CardError.pinBlocked {
            self.session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
            logger.error("\(String(localized: "nfcWrongPinBlocked"))", tag: "onUpdatePinCode")
            DispatchQueue.main.async {
                self.pinForMasterCard = nil
            }
        } catch let error {
            session?.stop(alertMessage: String(localized: "nfcPinCodeUpdateFailed"))
            logger.error("\(String(localized: "nfcPinCodeUpdateFailed")) \(error.localizedDescription)", tag: "onUpdatePinCode")
            DispatchQueue.main.async {
                self.pinCodeToSetup = nil
            }
        }
    }
    
    // *********************************************************
    // MARK: - Setup card pin code
    // *********************************************************
    func requestInitPinOnCard() {
        session = SatocardController(onConnect: onSetPinCode, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    
    private func onSetPinCode(cardChannel: CardChannel) -> Void {
        guard let pin = pinCodeToSetup else {
            session?.stop(alertMessage: String(localized: "nfcPinCodeIsNotDefined"))
            logger.info("\(String(localized: "nfcPinCodeIsNotDefined"))", tag: "onSetPinCode")
            return
        }
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            let pinBytes = Array(pin.utf8)
            _ = try cmdSet.cardSetup(pin_tries0: 5, pin0: pinBytes)
            
            session?.stop(alertMessage: String(localized: "nfcPinCodeSetSuccess"))
            logger.info("\(String(localized: "nfcPinCodeSetSuccess"))", tag: "onSetPinCode")
            
            DispatchQueue.main.async {
                self.pinForMasterCard = pin
                self.homeNavigationPath = .init()
            }
            
        } catch let error {
            session?.stop(errorMessage: String(localized: "nfcPinCodeSetFailed"))
            logger.error("\(String(localized: "nfcPinCodeSetFailed")) \(error.localizedDescription)", tag: "onSetPinCode")
        }
        
        DispatchQueue.main.async {
            self.pinCodeToSetup = nil
        }
    }
    
    // *********************************************************
    // MARK: - Setup backup card pin code
    // *********************************************************
    
    func requestInitPinOnBackupCard() {
        session = SatocardController(onConnect: onSetPinCodeForBackupCard, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanBackupCard"))
    }
    
    // TODO: merge with onSetPinCode(cardChannel: CardChannel)
    private func onSetPinCodeForBackupCard(cardChannel: CardChannel) -> Void {
        guard let pin = pinCodeToSetup else {
            session?.stop(alertMessage: String(localized: "nfcPinCodeIsNotDefined"))
            logger.error("\(String(localized: "nfcPinCodeIsNotDefined"))", tag: "onSetPinCodeForBackupCard")
            return
        }
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        do {
            let pinBytes = Array(pin.utf8)
            _ = try cmdSet.cardSetup(pin_tries0: 5, pin0: pinBytes)
            
            // optional: set label
            if let masterAuthentikeyBytes = self.authentikeyBytes {
                var masterLabel = self.masterCardLabel
                if masterLabel.count > 32 {
                    masterLabel = masterLabel.prefix(29) + "..."
                }
                let masterAuthentikeySecretBytes = [UInt8(masterAuthentikeyBytes.count)] + masterAuthentikeyBytes
                let masterAuthentikeyFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: masterAuthentikeySecretBytes)
                let backupLabel = "Backup for #\(masterAuthentikeyFingerprintBytes.bytesToHex):'\(masterLabel)'"
                let _ = try cmdSet.cardSetLabel(label: backupLabel)
                logger.info("Successfully set label for backup card", tag: "onSetPinCodeForBackupCard")
            }
            
            session?.stop(alertMessage: String(localized: "nfcPinCodeSetSuccess"))
            logger.info("\(String(localized: "nfcPinCodeSetSuccess"))", tag: "onSetPinCodeForBackupCard")
            
            DispatchQueue.main.async {
                self.pinForBackupCard = pin
                if self.homeNavigationPath.count >= 2 {
                    print("DEBUG self.homeNavigationPath.removeLast(2)") // TODO: check if happens
                    self.homeNavigationPath.removeLast(2)
                }
                // should be back to backup flow
            }
            
        } catch let error {
            session?.stop(errorMessage: String(localized: "nfcPinCodeSetFailed"))
            logger.error("\(String(localized: "nfcPinCodeSetFailed")) \(error.localizedDescription)", tag: "onSetPinCodeForBackupCard")
        }
        
        DispatchQueue.main.async {
            self.pinCodeToSetup = nil
        }
    }
}
