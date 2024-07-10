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
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
            }
            return
        }
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        let pinBytes = Array(pinForMasterCard.utf8)
        let pinBytesNew = Array(pinCodeToSetup.utf8)
                
        do {
            var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
            var rapdu = try cmdSet.cardChangePIN(oldPin: pinBytes, newPin: pinBytesNew)
            print("Pin Updated")
            self.pinForMasterCard = pinCodeToSetup
            self.pinCodeToSetup = nil
            DispatchQueue.main.async { [weak self] in
                self?.homeNavigationPath = .init()
            }
            session?.stop(alertMessage: String(localized: "nfcPinCodeUpdateSuccess"))
        } catch let error {
            print("Error: \(error)")
            self.pinCodeToSetup = nil
            logEvent(log: LogModel(type: .error, message: "onUpdatePinCode : \(error.localizedDescription)"))
            session?.stop(alertMessage: String(localized: "nfcPinCodeUpdateFailed"))
        }
    }
    
    // *********************************************************
    // MARK: - Setup card's pin code
    // *********************************************************
    func requestInitPinOnCard() {
        session = SatocardController(onConnect: onSetPinCode, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
    
    private func onSetPinCode(cardChannel: CardChannel) -> Void {
        guard let pin = pinCodeToSetup else {
            session?.stop(alertMessage: String(localized: "nfcPinCodeIsNotDefined"))
            return
        }
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        let pinBytes = Array(pin.utf8)
        var rapdu = APDUResponse(sw1: 0x00, sw2: 0x00, data: [])
        
        do {
            rapdu = try cmdSet.cardSetup(pin_tries0: 5, pin0: pinBytes)
            print("Pin Set")
            let (_, _, authentikeyHex) = try cmdSet.cardGetAuthentikey()
            session?.stop(alertMessage: String(localized: "nfcPinCodeSetSuccess"))
            homeNavigationPath = .init()
            // homeNavigationPath.append(NavigationRoutes.setupFaceId(pin))
        } catch let error {
            print("Error: \(error)")
            session?.stop(alertMessage: String(localized: "nfcPinCodeSetFailed"))
        }
        
        pinCodeToSetup = nil
    }
    
    // *********************************************************
    // MARK: - Setup backup card's pin code
    // *********************************************************
    
    func requestInitPinOnBackupCard() {
        session = SatocardController(onConnect: onSetPinCodeForBackupCard, onFailure: onDisconnection)
        session?.start(alertMessage: String(localized: "nfcScanBackupCard"))
    }
    
    private func onSetPinCodeForBackupCard(cardChannel: CardChannel) -> Void {
        guard let pin = pinCodeToSetup else {
            session?.stop(alertMessage: String(localized: "nfcPinCodeIsNotDefined"))
            return
        }
        
        cmdSet = SatocardCommandSet(cardChannel: cardChannel)
        
        let pinBytes = Array(pin.utf8)
        var rapdu = APDUResponse(sw1: 0x00, sw2: 0x00, data: [])
        
        do {
            rapdu = try cmdSet.cardSetup(pin_tries0: 5, pin0: pinBytes)
            print("Pin Set")
            session?.stop(alertMessage: String(localized: "nfcPinCodeSetSuccess"))
            self.pinForBackupCard = pin
            popToBackupFlow()
        } catch let error {
            print("Error: \(error)")
            session?.stop(alertMessage: String(localized: "nfcPinCodeSetFailed"))
        }
        
        pinCodeToSetup = nil
    }
}
