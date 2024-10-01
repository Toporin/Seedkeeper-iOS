//
//  FactoryResetResultView.swift
//  Seedkeeper
//
//  Created by Satochip on 23/09/2024.
//

import Foundation
import SwiftUI

struct FactoryResetResultView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    var resultCode: ResetResult
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Spacer()
                    .frame(height: 60)
                
                switch resultCode {
                case .success:
                    SatoText(text: "resetResultSuccessBold", style: .SKStrongBodyDark)
                default:
                    SatoText(text: "resetResultFailedBold", style: .SKStrongBodyDark)
                }
                
                
                Spacer()
                    .frame(height: 16)
                
                //SatoText(text: "congratsInfoSubtitle", style: .SKStrongBodyDark) // TODO: provide details
                
                Spacer()
                
                Image("il_backup_congrats") // TODO: image
                    .resizable()
                    .frame(width: 300, height: 268)

                Spacer()
                
                SKButton(text: String(localized: "home"), style: .regular, horizontalPadding: 66, action: {
                    cardState.isCardDataAvailable = false
                    homeNavigationPath = .init()
                })
                
                Spacer().frame(height: 16)

            }
            .padding([.leading, .trailing], Dimensions.lateralPadding)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                SatoText(text: "factoryResetResultViewTitle", style: .lightTitleDark)
            }
        }
    }
}
