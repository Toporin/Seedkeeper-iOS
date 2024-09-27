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
                    DispatchQueue.main.async {
                        self.homeNavigationPath.append(NavigationRoutes.pinCode(.dismiss))
                    }
                    return
                }
                
                cmdSet = SatocardCommandSet(cardChannel: cardChannel)
                
                do {
                    var cardStatus: CardStatus?
                    (_, cardStatus, _) = try self.selectApplet()
                    
                    let pinBytes = Array(pinForMasterCard.utf8)
                    var response = try cmdSet.cardVerifyPIN(pin: pinBytes)
                        
                    let isAuthentikeyValid = try isAuthentikeyValid(for: .master)
                    if !isAuthentikeyValid {
                        logEvent(log: LogModel(type: .error, message: "requestCardLogs : invalid AuthentiKey"))
                        session?.stop(errorMessage: String(localized: "nfcAuthentikeyError"))
                        return
                    }
                        
                    var (logs, nbAvailable, nbTotal) = try cmdSet.seedkeeperPrintLogs(printAll: true)
                        
                    session?.stop(alertMessage: "\(String(localized: "nfcLogsFetchedSuccessful"))")
                    
                    DispatchQueue.main.async {
                        self.cardLogs = logs
                        self.nbTotalLogs = nbTotal
                        self.nbAvailableLogs = nbAvailable
                        self.homeNavigationPath.append(NavigationRoutes.showCardLogs)
                    }
                    
                    
                } catch let error {
                    print("requestCardLogs catch error: \(error)")
                    logEvent(log: LogModel(type: .error, message: "requestCardLogs : \(error.localizedDescription)"))
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                }
                
            },
            onFailure: { [weak self] error in
                // these are errors related to NFC communication
                guard let self = self else { return }
                print("requestCardLogs onFailure: \(error)")
                self.onDisconnection(error: error)
            }
        )// session
        
        session?.start(alertMessage: String(localized: "nfcScanMasterCard")) // TODO: change txt? nfcHoldSatodime
    }
    
}

