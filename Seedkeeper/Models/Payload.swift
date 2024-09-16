//
//  Payload.swift
//  Seedkeeper
//
//  Created by Satochip on 16/09/2024.
//

import SatochipSwift

protocol Payload {
    var label: String { get set }
    var type: SeedkeeperSecretType {get set}
    var subtype: UInt8 {get set}
    
    func getPayloadBytes() -> [UInt8]
    func getFingerprintBytes() -> [UInt8]
    //func getQrCodeString() -> String // TODO: return a string for QR widget
}
