//
//  SatoStatusView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import Foundation
import SwiftUI

struct SatoStatusView: View {
    @EnvironmentObject var cardState: CardState
    
    func getCardStatusIcon() -> String {
        switch cardState.certificateCode {
        case .unknown:
            return "satochip_logo_dark"
        case .success:
            return "il_authenitc"
        default:
            return "il_not_authentic"
        }
    }
    
    var body: some View {
        Image(self.getCardStatusIcon())
            .resizable()
            .frame(width: 40, height: 40)
    }
}
