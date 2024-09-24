//
//  CardState+Helpers.swift
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
    // MARK: - Helpers
    // *********************************************************
    func cleanShowSecret() {
        currentSecretHeader = nil
        currentSecretObject = nil
        currentSecretPayload = nil
    }
    
    internal func resetState() {
        certificateCode = .unknown
        isCardDataAvailable = false
        
        masterSecretHeaders = []
    }
    
    internal func popToBackupFlow() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if homeNavigationPath.count >= 2 {
                homeNavigationPath.removeLast(2)
            }
        }
    }
    
    internal func selectApplet() throws -> (APDUResponse, CardStatus?, CardType) {
        var selectApdu: APDUResponse?
        var cardStatus: CardStatus?
        var cardType: CardType?
        
        (selectApdu, cardType) = try cmdSet.selectApplet(cardType: .seedkeeper)
        
        guard let selectApdu = selectApdu,
                let cardType = cardType else {
            throw SatocardError.invalidResponse
        }
        
        // for Seedkeeper v2 and higher, the cardStatus is already provided in select response
        if selectApdu.data.count >= 7 {
            do {
                cardStatus = try CardStatus(rapdu: selectApdu)
            } catch let error {
                print("selectApplet: failed to parse cardStatus from selectApdu: \(error)")
            }
        }
        
        return (selectApdu, cardStatus, cardType)
    }
    
    internal func getCardStatus() throws -> CardStatus {
        var statusApdu: APDUResponse?
        
        statusApdu = try cmdSet.cardGetStatus()
        guard let apdu = statusApdu else {
            throw SatocardError.invalidResponse
        }
        
        do {
            var cardStatus = try CardStatus(rapdu: apdu)
            return cardStatus
        } catch let error {
            throw SatocardError.invalidResponse
        }
    }
    
    internal func selectAppletAndGetStatus() throws -> (CardStatus, CardType) {
        var selectApdu: APDUResponse?
        var cardType: CardType?
        
        (selectApdu, cardType) = try cmdSet.selectApplet(cardType: .seedkeeper)
        
        guard let selectApdu = selectApdu,
                let cardType = cardType else {
            throw SatocardError.invalidResponse
        }
        
        // for Seedkeeper v2 and higher, the cardStatus is already provided in select response
        if selectApdu.data.count >= 7 {
            do {
                var cardStatus = try CardStatus(rapdu: selectApdu)
                return (cardStatus, cardType)
            } catch let error {
                print("selectApplet: failed to parse cardStatus from selectApdu: \(error)")
            }
        }
        
        // if cardStatus cannot be recovered from select apdu, send getStatus command
        do {
            var statusApdu = try cmdSet.cardGetStatus()
            var cardStatus = try CardStatus(rapdu: statusApdu)
            return (cardStatus, cardType)
        } catch let error {
            throw SatocardError.invalidResponse
        }
        
    }
    
    internal func verifyCardAuthenticity(cardType: ScannedCardType) throws {
        let (certificateCode, certificateDic) = try cmdSet.cardVerifyAuthenticity()
        DispatchQueue.main.async {
            switch cardType {
            case .master:
                self.certificateCode = certificateCode
                self.certificateDic = certificateDic
            case .backup:
                self.certificateCodeForBackup = certificateCode
                self.certificateDicForBackup = certificateDic
            }
        }
    }
    
    func getReasonFromPkiReturnCode(pkiReturnCode: PkiReturnCode) -> String {
        switch(pkiReturnCode) {
        case PkiReturnCode.FailedToVerifyDeviceCertificate:
            return "_reason_wrong_sig"
        case PkiReturnCode.FailedChallengeResponse:
            return "_reason_wrong_challenge"
        case PkiReturnCode.unknown:
            return "_reason_unknown"
        default:
            return "Reason: \(pkiReturnCode)"
        }
    }
    
    internal func fetchAuthentikey(cardType: ScannedCardType) throws {
        let (_, authentikeyBytes, authentikeyHex) = try cmdSet.cardGetAuthentikey()
        DispatchQueue.main.async {
            switch cardType {
            case .master:
                //self.authentikeyHex = authentikeyHex
                self.authentikeyBytes = authentikeyBytes
            case .backup:
                //self.authentikeyHexForBackup = authentikeyHex
                self.authentikeyBytesForBackup = authentikeyBytes
            }
        }
    }
    
    internal func isAuthentikeyValid(for cardType: ScannedCardType) throws -> Bool {
        let (_, authentikeyBytes, _) = try cmdSet.cardGetAuthentikey()
        switch cardType {
        case .master:
            return self.authentikeyBytes == authentikeyBytes
        case .backup:
            return self.authentikeyBytesForBackup == authentikeyBytes
        }
    }
    
    func getCardVersionInt(cardStatus: CardStatus) -> Int {
        return Int(cardStatus.protocolMajorVersion) * (1<<24) +
               Int(cardStatus.protocolMinorVersion) * (1<<16) +
               Int(cardStatus.appletMajorVersion) * (1<<8) +
               Int(cardStatus.appletMinorVersion)
    }
    
    public func checkEqual<T: Equatable>(_ lhs: T, _ rhs: T, tag: String) throws {
        // let log = LoggerService.shared
        if (lhs != rhs){
            let msg = "CheckEqual failed: got \(lhs) but expected \(rhs) in \(tag)"
            // log.error(msg, tag: tag)
            throw SatocardError.testError("[\(tag)] \(msg)")
        }
        else {
            // log.debug("CheckEqual ok for: \(lhs)", tag: tag)
        }
    }

}
