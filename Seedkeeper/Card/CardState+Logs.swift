//
//  CardState+Logs.swift
//  Seedkeeper
//
//  Created by Satochip on 26/09/2024.
//

import Foundation
import CoreNFC
import SatochipSwift
import CryptoSwift
import Combine
import SwiftUI
import MnemonicSwift

extension CardState {
    
    func requestCardLogs(){

        session = SatocardController(
            onConnect: { [weak self] cardChannel in
                guard let self = self else { return }
                
                guard let pinForMasterCard = pinForMasterCard else {
                    session?.stop(errorMessage: String(localized: "nfcPinCodeIsNotDefined"))
                    logger.info("\(String(localized: "nfcPinCodeIsNotDefined"))", tag: "requestCardLogs")
                    DispatchQueue.main.async {
                        self.homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
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
                            logger.error("\(String(localized: "nfcAuthentikeyError"))", tag: "requestCardLogs")
                            return
                        }
                    }
                    
                    let pinBytes = Array(pinForMasterCard.utf8)
                    _ = try cmdSet.cardVerifyPIN(pin: pinBytes)
                    
                    // Note: nbTotal is the total number of events logged, but max nbAvailable are stored.
                    // so the actual number of events stored is min(nbTotal, nbAvailable)
                    let (logs, nbTotal, nbAvailable) = try cmdSet.seedkeeperPrintLogs(printAll: true)
                        
                    session?.stop(alertMessage: "\(String(localized: "nfcLogsFetchedSuccessful"))")
                    logger.info("\(String(localized: "nfcLogsFetchedSuccessful"))", tag: "requestCardLogs")
                    
                    DispatchQueue.main.async {
                        self.cardLogs = logs
                        self.nbTotalLogs = nbTotal
                        self.nbAvailableLogs = min(nbTotal, nbAvailable)
                        self.homeNavigationPath.append(NavigationRoutes.showCardLogs)
                    }
                    
                } catch CardError.wrongPIN(let retryCounter) {
                    session?.stop(errorMessage: "\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)")
                    logger.error("\(String(localized: "nfcWrongPinWithTriesLeft")) \(retryCounter)", tag: "requestCardLogs")
                    DispatchQueue.main.async {
                        self.pinForMasterCard = nil
                    }
                } catch CardError.pinBlocked {
                    session?.stop(errorMessage: "\(String(localized: "nfcWrongPinBlocked"))")
                    logger.error("\(String(localized: "nfcWrongPinBlocked"))", tag: "requestCardLogs")
                    DispatchQueue.main.async {
                        self.pinForMasterCard = nil
                    }
                } catch let error {
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    logger.error("\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)", tag: "requestCardLogs")
                }
                
            },
            onFailure: { [weak self] error in
                // these are errors related to NFC communication
                guard let self = self else { return }
                self.onDisconnection(error: error)
            }
        )// session
        
        session?.start(alertMessage: String(localized: "nfcScanMasterCard"))
    }
    
}

