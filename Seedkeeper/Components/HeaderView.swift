//
//  HeaderView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import Foundation
import SwiftUI

struct HeaderView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    @Binding var showCardNeedsToBeScannedAlert: Bool
    
    // MARK: - Literals
    let viewTitle: String = "Seedkeeper"
    
    var body: some View {
        HStack {
            
            // Logo with authenticity status
            SatoStatusView()
                .padding(.leading, 22)
                .onTapGesture(count: 1){
                    if let _ = cardState.masterCardStatus {
                        homeNavigationPath.append(NavigationRoutes.authenticity)
                    } else {
                        showCardNeedsToBeScannedAlert = true
                    }
                }
            
            Spacer()
            
            // Title
            SatoText(text: viewTitle, style: .title)
            
            Spacer()
            
            if let _ = cardState.masterCardStatus {
                Button(action: {
                    cardState.pinForMasterCard = nil
                    cardState.lastTimeForMasterCardPin = nil
                    cardState.scan(for: .master)
                }) {
                    Image("ic_refresh_dark")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                
                Spacer()
                    .frame(width: 8)
            }
            
            // Menu button
            Button(action: {
                homeNavigationPath.append(NavigationRoutes.menu)
            }) {
                Image("ic_dots_vertical_black")
                    .resizable()
                    .frame(width: 24, height: 24)
            }.padding(.trailing, 22)
        }
        .frame(height: 48)
    }
}
