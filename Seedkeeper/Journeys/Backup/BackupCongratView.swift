//
//  BackupCongratView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 24/05/2024.
//

import Foundation
import SwiftUI

struct BackupCongratsView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Spacer()
                    .frame(height: 60)
                
                SatoText(text: "**congrats**", style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 16)
                
                SatoText(text: "congratsInfoSubtitle", style: .SKStrongBodyDark)
                
                Spacer()
                
                Image("il_backup_congrats")
                    .resizable()
                    .frame(width: 300, height: 268)

                Spacer()
                
                SKButton(text: String(localized: "home"), style: .regular, horizontalPadding: 66, action: {
                    cardState.resetStateForBackupCard(clearPin: true)
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
                SatoText(text: "backupCongratsViewTitle", style: .lightTitleDark)
            }
        }
    }
}
