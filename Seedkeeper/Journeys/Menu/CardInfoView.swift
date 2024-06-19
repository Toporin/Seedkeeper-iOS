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
    //let authentikeyTitle = "authentikeyTitle" //TODO: translate
    
    let ownerTitle = "cardOwnershipStatus"
    let ownerText = "youAreTheCardOwner"
    let notOwnerText = "youAreNotTheCardOwner"
    let unclaimedOwnershipText = "cardHasNoOwner"
    let unknownOwnershipText = "Scan card to get ownership status"
    
    let cardVersionTitle = "cardVersion"
    
    let cardGenuineTitle = "**cardAuthenticity**"
    let cardGenuineText = "thisCardIsGenuine"
    let cardNotGenuineText = "thisCardIsNotGenuine"
    let certButtonTitle = "certDetails"
    
    func getCardVersionString() -> String {
        if let cardStatus = cardState.cardStatus {
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
                SatoText(text: "**\(cardVersionTitle)**", style: .lightSubtitleDark)
                Spacer()
                    .frame(height: 14)
                CardInfoBox(text: self.getCardVersionString(), backgroundColor: Colors.lightMenuButton)
                
                Spacer()
                    .frame(height: 20)
                
                SatoText(text: "**Card label**", style: .lightSubtitleDark)
                Spacer()
                    .frame(height: 14)

                EditableCardInfoBox(mode: .text(self.cardState.cardLabel), backgroundColor: Colors.lightMenuButton) { result in
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
                
                SatoText(text: "**Pin code**", style: .lightSubtitleDark)
                Spacer()
                    .frame(height: 14)
                EditableCardInfoBox(mode: .pin, backgroundColor: Colors.lightMenuButton) { result in
                    switch result {
                    case .pin:
                        guard let cardStatus = cardState.cardStatus else {
                            return
                        }
                        homeNavigationPath.append(NavigationRoutes.editPinCode)
                    default:
                        break
                    }
                }
                
                Spacer()
                
                Rectangle()
                    .frame(width: .infinity, height: 2)
                    .foregroundColor(Colors.separator)
                    .padding([.leading, .trailing], 31)
                
                Spacer()
                
                // CERTIFICATE STATUS
                SatoText(text: cardGenuineTitle, style: .lightSubtitleDark)
                Spacer()
                    .frame(height: 14)
                CardInfoBox(
                    text: cardState.certificateCode == .success ? cardGenuineText : cardNotGenuineText,
                    backgroundColor: cardState.certificateCode == .success ? Colors.ledGreen : Colors.ledRed)
                {
                    self.homeNavigationPath.append(NavigationRoutes.authenticity)
                }
                
                Spacer()

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
                SatoText(text: "cardInfoViewTitle", style: .lightTitleDark)
            }
        }
    }
}
