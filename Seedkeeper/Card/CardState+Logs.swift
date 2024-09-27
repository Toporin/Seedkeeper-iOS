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
                    let cardStatus: CardStatus?
                    (_, cardStatus, _) = try self.selectApplet()
                    
                    let pinBytes = Array(pinForMasterCard.utf8)
                    let response = try cmdSet.cardVerifyPIN(pin: pinBytes)
                        
                    let isAuthentikeyValid = try isAuthentikeyValid(for: .master)
                    if !isAuthentikeyValid {
                        session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                        logger.error("\(String(localized: "nfcAuthentikeyError"))", tag: "requestCardLogs")
                        return
                    }
                        
                    let (logs, nbAvailable, nbTotal) = try cmdSet.seedkeeperPrintLogs(printAll: true)
                        
                    session?.stop(alertMessage: "\(String(localized: "nfcLogsFetchedSuccessful"))")
                    logger.info("\(String(localized: "nfcLogsFetchedSuccessful"))", tag: "requestCardLogs")
                    
                    DispatchQueue.main.async {
                        self.cardLogs = logs
                        self.nbTotalLogs = nbTotal
                        self.nbAvailableLogs = nbAvailable
                        self.homeNavigationPath.append(NavigationRoutes.showCardLogs)
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
        
        session?.start(alertMessage: String(localized: "nfcScanMasterCard")) // TODO: change txt? nfcHoldSatodime
    }
    
}

