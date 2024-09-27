//
//  CardState+FactoryReset.swift
//  Seedkeeper
//
//  Created by Satochip on 23/09/2024.
//

import Foundation
import CoreNFC
import SatochipSwift
import CryptoSwift
import Combine
import SwiftUI
import MnemonicSwift

extension CardState {
    
    func requestFactoryReset(){

        session = SatocardController(
            onConnect: { [weak self] cardChannel in
                guard let self = self else { return }
                
                cmdSet = SatocardCommandSet(cardChannel: cardChannel)
                
                do {
                    var cardStatus: CardStatus?
                    (_, cardStatus, _) = try self.selectApplet()
                    
                    if cardStatus == nil {
                        // that's for v1 only , since v2 and higher get the status in select response
                        if self.masterCardStatus != nil {
                            cardStatus = self.masterCardStatus
                        } else {
                            // fetch from the card
                            // for factory reset, it is important to only fetch cardStatus before initiating reset, since sending the getCardStatus command during factory reset abort the process (with code 0xFFFF)
                            cardStatus = try getCardStatus()
                            
                            DispatchQueue.main.async {
                                self.masterCardStatus = cardStatus
                            }
                        }
                    }
                    
                    // at this point, cardStatus should be available
                    guard let cardStatus = cardStatus else {
                        session?.stop(alertMessage: String(localized: "nfcFailedToConnect"))
                        logger.error("\(String(localized: "nfcFailedToConnect"))", tag: "requestFactoryReset")
                        DispatchQueue.main.async {
                            self.homeNavigationPath.append(NavigationRoutes.factoryResetResult(.unknown))
                        }
                        return
                    }
                    
                    // there is no point to reset card if it is not initialized
                    if !cardStatus.setupDone {
                        session?.stop(alertMessage: String(localized: "nfcCardNeedsSetup"))
                        logger.warning("\(String(localized: "nfcCardNeedsSetup"))", tag: "requestFactoryReset")
                        DispatchQueue.main.async {
                            self.homeNavigationPath.append(NavigationRoutes.factoryResetResult(.notSetup))
                        }
                    }
                    
                    var rapdu: APDUResponse? = nil
                    let version = cardStatus.protocolVersion
                    logger.warning("Start factory reset for Seedkeeper v\(version)", tag: "requestFactoryReset")
                    
                    // Send factory reset command
                    if version == 1 {
                        // factory reset v1 command (legacy)
                        rapdu = try cmdSet.cardSendResetCommand()
                        logger.warning("Factory reset sent reset command!", tag: "requestFactoryReset")
                        
                    } else {
                        // factory reset v2
                        if cardStatus.pin0RemainingTries > 0 {
                            // send random pin until card blocks
                            var pinBytes = [UInt8](repeating: 0, count: 8)
                            let status = SecRandomCopyBytes(kSecRandomDefault, pinBytes.count, &pinBytes)
                            if status == errSecSuccess {
                                do {
                                    rapdu = try cmdSet.cardVerifyPIN(pin: pinBytes)
                                } catch let error {
                                    // catch wrong pin error
                                    logger.warning("Factory reset sent wrong PIN command! \(error.localizedDescription)", tag: "requestFactoryReset")
                                    rapdu = APDUResponse(sw1: 0x63, sw2: 0xC0, data: [UInt8]())
                                }
                            }
                        } else if cardStatus.puk0RemainingTries > 0 {
                            // send random puk until card blocks
                            var pukBytes = [UInt8](repeating: 0, count: 8)
                            let status = SecRandomCopyBytes(kSecRandomDefault, pukBytes.count, &pukBytes)
                            if status == errSecSuccess {
                                do {
                                    rapdu = try cmdSet.cardUnblockPIN(puk: pukBytes)
                                } catch StatusWord.resetToFactory {
                                    rapdu = APDUResponse(sw1: 0xFF, sw2: 0x00, data: [UInt8]())
                                } catch CardError.wrongPIN(let retryCounter) {
                                    rapdu = APDUResponse(sw1: 0x63, sw2: UInt8(0xC0 ^ retryCounter), data: [UInt8]())
                                } catch CardError.wrongPINLegacy {
                                    rapdu = APDUResponse(sw1: 0x9C, sw2: 0x02, data: [UInt8]())
                                } catch CardError.pinBlocked {
                                    rapdu = APDUResponse(sw1: 0x9C, sw2: 0x0C, data: [UInt8]())
                                } catch CardError.setupNotDone {
                                    rapdu = APDUResponse(sw1: 0x9C, sw2: 0x04, data: [UInt8]())
                                } catch {
                                    // other errors
                                    rapdu = APDUResponse(sw1: 0x00, sw2: 0x00, data: [UInt8]())
                                }
                                logger.warning("Factory reset sent wrong PUK command - sw: \(String(format:"%04X", rapdu?.data ?? 0x00))", tag: "requestFactoryReset")
                            }
                        } // if pin else puk
                    } // if version
                    
                    // check result of command
                    if let rapdu = rapdu {
                        
                        // update NFC toast
                        if rapdu.sw1 == 0xFF && rapdu.sw2 == 0x00 {
                            session?.stop(alertMessage: String(localized: "resetResultSuccessBold"))
                            logger.warning("\(String(localized: "resetResultSuccessBold"))", tag: "requestFactoryReset")
                        } else if rapdu.sw1 == 0xFF && rapdu.sw2 == 0xFF {
                            session?.stop(alertMessage: String(localized: "resetResultFailedBold"))
                            logger.warning("\(String(localized: "resetResultFailedBold"))", tag: "requestFactoryReset")
                        } else if rapdu.sw1 == 0xFF && rapdu.sw2 > 0x00 {
                            session?.stop(alertMessage: String(localized: "resetResultSentBold"))
                            logger.warning("\(String(localized: "resetResultSentBold"))", tag: "requestFactoryReset")
                        } else {
                            session?.stop(alertMessage: String(localized: "resetResultSentBold"))
                            logger.warning("\(String(localized: "resetResultSentBold"))", tag: "requestFactoryReset")
                        }
                        
                        // update screen
                        DispatchQueue.main.async {
                            if rapdu.sw1 == 0xFF && rapdu.sw2 == 0x00 {
                                // factory reset successful!
                                self.resetRemainingSteps = 0
                                self.masterSecretHeaders.removeAll() // remove all secret headers from cache
                                self.homeNavigationPath.append(NavigationRoutes.factoryResetResult(.success))
                            } else if rapdu.sw1 == 0xFF && rapdu.sw2 == 0xFF {
                                // factory reset aborted
                                self.resetRemainingSteps = 0xFF
                                self.homeNavigationPath.append(NavigationRoutes.factoryResetResult(.aborted))
                            } else if rapdu.sw1 == 0xFF && rapdu.sw2 > 0x00 {
                                // V1: command sent successfully, may need to be repeated several times
                                self.resetMode = .sendResetCommand
                                self.resetRemainingSteps = rapdu.sw2
                            } else if (rapdu.sw1 == 0x9C && rapdu.sw2 == 0x0C) || // pin identity blocked
                                    (rapdu.sw1 == 0x63 && (rapdu.sw2 & UInt8(0xF0)) == 0xC0) || // wrong pin
                                    (rapdu.sw1 == 0x9C && rapdu.sw2 == 0x02) // wrong pin (legacy)
                            {
                                // V2: command sent successfully, may need to be repeated several times
                                self.resetMode = .sendResetCommand
                                self.resetRemainingSteps = cardStatus.pin0RemainingTries + cardStatus.puk0RemainingTries - 1
                            } else if rapdu.sw1 == 0x9C && rapdu.sw2 == 0x04 {
                                // setup not done
                                self.resetRemainingSteps = 0xFF
                                self.homeNavigationPath.append(NavigationRoutes.factoryResetResult(.notSetup))
                            } else if rapdu.sw1 == 0x6D && rapdu.sw2 == 0x00 {
                                // factory reset unsupported
                                self.resetRemainingSteps = 0xFF
                                self.homeNavigationPath.append(NavigationRoutes.factoryResetResult(.unsupported))
                            } else {
                                // unknown
                                self.resetRemainingSteps = 0xFF
                                self.homeNavigationPath.append(NavigationRoutes.factoryResetResult(.unknown))
                            }
                        }
                        
                    } // if
                    
                } catch let error {
                    session?.stop(errorMessage: "\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)")
                    logger.error("\(String(localized: "nfcErrorOccured")) \(error.localizedDescription)", tag: "requestFactoryReset")
                }
                
            },
            onFailure: { [weak self] error in
                // these are errors related to NFC communication
                guard let self = self else { return }
                self.onDisconnection(error: error)
            }
        )// session
        
        session?.start(alertMessage: String(localized: "nfcScanCardForReset"))
    }
    
}
