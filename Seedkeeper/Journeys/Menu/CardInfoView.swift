//
//  CardInfoView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 02/05/2024.
//

import Foundation
import SwiftUI

struct CardInfoView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    @State var shouldShowAuthenticityScreen = false
    
    // MARK: - Literals
    let title = "cardInfo"
//    let authentikeyTitle = "cardAuthentikeyTitle" //TODO: translate
    
//    let ownerTitle = "cardOwnershipStatus"
//    let ownerText = "youAreTheCardOwner"
//    let notOwnerText = "youAreNotTheCardOwner"
//    let unclaimedOwnershipText = "cardHasNoOwner"
//    let unknownOwnershipText = "Scan card to get ownership status"
    
//    let cardVersionTitle = "cardVersion"
    
    let cardGenuineTitle = String(localized: "cardAuthenticity")
    let cardGenuineText = String(localized: "thisCardIsGenuine")
    let cardNotGenuineText = String(localized: "thisCardIsNotGenuine")
//    let certButtonTitle = "certDetails"
    
    func getCardVersionString() -> String {
        if let cardStatus = cardState.masterCardStatus {
            let str = "Seedkeeper v\(cardStatus.protocolMajorVersion).\(cardStatus.protocolMinorVersion)-\(cardStatus.appletMajorVersion).\(cardStatus.appletMinorVersion)"
            return str
        } else {
            return "n/a"
        }
    }

    // MARK: - View
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                    .frame(height: 66)
                
                // CARD VERSION
                SatoText(text: "cardVersionTitle", style: .lightSubtitleDark)
                Spacer()
                    .frame(height: 14)
                CardInfoBox(text: self.getCardVersionString(), backgroundColor: Colors.lightMenuButton)
                
                Spacer()
                    .frame(height: 20)
                
                // CARD LABEL
                SatoText(text: "cardLabel", style: .lightSubtitleDark)
                Spacer()
                    .frame(height: 14)

                EditableCardInfoBox(mode: .text(self.cardState.masterCardLabel), backgroundColor: Colors.lightMenuButton) { result in
                    switch result {
                    case .text(let value):
                        print("Edited text : \(value)")
                        self.cardState.requestSetCardLabel(label: value)
                    default:
                        break
                    }
                }
                
                Spacer()
                    .frame(height: 20)
                
                // CHANGE PIN
                SatoText(text: "pinCodeBold", style: .lightSubtitleDark)
                Spacer()
                    .frame(height: 14)
                EditableCardInfoBox(mode: .pin, backgroundColor: Colors.lightMenuButton) { result in
                    switch result {
                    case .pin:
                        guard let _ = cardState.masterCardStatus else {
                            return
                        }
                        homeNavigationPath.append(NavigationRoutes.editPinCodeRequest)
                    default:
                        break
                    }
                }
                
                Spacer()
                
//                Rectangle()
//                    .frame(width: .infinity, height: 2)
//                    .foregroundColor(Colors.separator)
//                    .padding([.leading, .trailing], 31)
//
//                Spacer()
                
                // CERTIFICATE STATUS
                SatoText(text: cardGenuineTitle, style: .lightSubtitleDark)
                Spacer()
                    .frame(height: 14)
                CardInfoBox(
                    text: cardState.certificateCode == .success ? cardGenuineText : cardNotGenuineText,
                    backgroundColor: cardState.certificateCode == .success ? Colors.authenticGreen : Colors.ledRed)
                {
                    self.homeNavigationPath.append(NavigationRoutes.authenticity)
                }
                
                Spacer()

                // CARD AUTHENTIKEY
                SatoText(text: "cardAuthentikeyTitle", style: .lightSubtitleDark)
                Spacer()
                    .frame(height: 14)
                CardInfoBox(text: cardState.authentikeyBytes?.bytesToHex ?? "n/a", backgroundColor: Colors.lightMenuButton)
                
                Spacer()
                    .frame(height: 20)
                
                
//                // WARNING: CARD RESET TO FACTORY
//                SatoText(text: "cardResetToFactory", style: .lightSubtitleDark)
//                Spacer()
//                    .frame(height: 14)
//                CardInfoBox(
//                    text: "Warning: this will erase all secrets!", //TODO: localize
//                    backgroundColor: Colors.ledRed)
//                {
//                    self.homeNavigationPath.append(NavigationRoutes.factoryReset)
//                }
                
                
            }.padding([.leading, .trailing], 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            homeNavigationPath.removeLast()
        }) {
            Image("ic_back_dark")
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                SatoText(text: title, style: .lightTitleDark)
            }
        }
    }
}
