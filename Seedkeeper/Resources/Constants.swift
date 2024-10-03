//
//  Constants.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 21/06/2024.
//

import Foundation

struct Constants {
    static let moreInfo = "https://satochip.io/product/seedkeeper/"
    
    struct Keys {
        static let firstTimeUse = "isFirstTimeUse"
    }
    
    static let minSecretsCountToDisplayFilterSearch = 5
    static let pinExpirationInSeconds = 300 //180
    
    // Applet limitations
    static let MAX_CARD_LABEL_SIZE = 64
    static let MAX_LABEL_SIZE = 127
    static let MAX_FIELD_SIZE = 255
    static let MAX_FIELD_SIZE_16B = 65535
    static let MAX_SECRET_SIZE_FOR_V1 = 255
}
