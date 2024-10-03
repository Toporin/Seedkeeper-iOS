//
//  CardInfoView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 02/05/2024.
//

import Foundation
import SwiftUI
import SatochipSwift

struct CardInfoView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    
    // MARK: - Literals
    let title = "cardInfo"
    
    let cardGenuineTitle = String(localized: "cardAuthenticity")
    let cardGenuineText = String(localized: "thisCardIsGenuine")
    let cardNotGenuineText = String(localized: "thisCardIsNotGenuine")
    
    func getCardVersionString() -> String {
        if let cardStatus = cardState.masterCardStatus {
            let str = "Seedkeeper v\(cardStatus.protocolMajorVersion).\(cardStatus.protocolMinorVersion)-\(cardStatus.appletMajorVersion).\(cardStatus.appletMinorVersion)"
            return str
        } else {
            return "n/a"
        }
    }
    
    func getSeedkeeperDataString() -> String {
        if let seedkeeperStatus = cardState.masterSeedkeeperStatus,
           let cardStatus = cardState.masterCardStatus{
            // note: memory might not be up-to-date if secrets were deleted in the meantime
            return "Seedkeeper v\(cardStatus.protocolMajorVersion).\(cardStatus.protocolMinorVersion)-\(cardStatus.appletMajorVersion).\(cardStatus.appletMinorVersion) \n" +
                    String(localized: "numberSecrets") + " \(cardState.masterSecretHeaders.count) \n" +
                    String(localized: "availableMemory") + " \(seedkeeperStatus.freeMemory) bytes \n" +
                    String(localized: "totalMemory") + " \(seedkeeperStatus.totalMemory) bytes"
        } else {
            return String(localized: "numberSecrets") + " \(cardState.masterSecretHeaders.count)"
        }
    }

    func getAuthentikeyData() -> String {
        if let authentikeyBytes = cardState.authentikeyBytes {
            let authentikeyFingerprintBytes = SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: [UInt8(authentikeyBytes.count)] + authentikeyBytes)
            return ("#" + authentikeyFingerprintBytes.bytesToHex + ":" + authentikeyBytes.bytesToHex)
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
            
            ScrollViewReader { scrollValue in
                ScrollView {

                    VStack {
                        Spacer()
                            .frame(height: 66)
                        
                        // SEEDKEEPER DATA
                        SatoText(text: "**Seedkeeper status**", style: .lightSubtitleDark)
                        Spacer()
                            .frame(height: 14)
                        //CardInfoBox(text: self.getSeedkeeperDataString(), backgroundColor: Colors.lightMenuButton, lineLimit: 3)
                        SatoText(text: self.getSeedkeeperDataString(), style: .SKStrongBodyLight)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                            //.frame(height: 180)
                            .background(Colors.lightMenuButton)
                            .cornerRadius(20)
                        
                        Spacer()
                            .frame(height: 20)
                        
                        // CARD VERSION
                        //                SatoText(text: "cardVersionTitle", style: .lightSubtitleDark)
                        //                Spacer()
                        //                    .frame(height: 14)
                        //                CardInfoBox(text: self.getCardVersionString(), backgroundColor: Colors.lightMenuButton)
                        //
                        //                Spacer()
                        //                    .frame(height: 20)
                        
                        // CARD LABEL
                        SatoText(text: "cardLabel", style: .lightSubtitleDark)
                        Spacer()
                            .frame(height: 14)
                        CardInfoBox(text: self.cardState.masterCardLabel, backgroundColor: Colors.lightMenuButton)
                        {
                            //TODO: label edit screen?
                            homeNavigationPath.append(NavigationRoutes.editLabel(self.cardState.masterCardLabel))
                        }
                        
                        Spacer()
                            .frame(height: 20)
                        
                        // CHANGE PIN
                        SatoText(text: "pinCodeBold", style: .lightSubtitleDark)
                        Spacer()
                            .frame(height: 14)
                        CardInfoBox(text: "updatePinButton", backgroundColor: Colors.lightMenuButton)
                        {
                            guard let _ = cardState.masterCardStatus else {
                                return
                            }
                            homeNavigationPath.append(NavigationRoutes.editPinCodeRequest)
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
                        CardInfoBox(text: getAuthentikeyData(), backgroundColor: Colors.lightMenuButton)
                        {
                            // copy
                            UIPasteboard.general.string = getAuthentikeyData()
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                generator.impactOccurred()
                            }
                        }
                        
                        Spacer()
                            .frame(height: 20)
                        
                        // CARD LOGS
                        SatoText(text: "cardLogsTitle", style: .lightSubtitleDark)
                        Spacer()
                            .frame(height: 14)
                        CardInfoBox(text: "cardLogsButton", backgroundColor: Colors.lightMenuButton)
                        {
                            cardState.requestCardLogs()
                        }
                        
                        Spacer()
                            .frame(height: 20)
                        
                    }.padding([.leading, .trailing], 20)
                    
                } //ScrollView
            }// ScrollViewReader
        }// Zstack
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
