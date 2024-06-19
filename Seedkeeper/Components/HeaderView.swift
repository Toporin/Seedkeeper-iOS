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
    // MARK: - Literals
    let viewTitle: String = "Seedkeeper"
    
    var body: some View {
        HStack {
            
            // Logo with authenticity status
            SatoStatusView()
                .padding(.leading, 22)
            
            Spacer()
            
            // Title
            SatoText(text: viewTitle, style: .title)
            
            Spacer()
            
            if let _ = cardState.cardStatus {
                Button(action: {
                    cardState.scan()
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
