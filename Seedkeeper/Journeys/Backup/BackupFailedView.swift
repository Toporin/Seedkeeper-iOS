//
//  BackupFailedView.swift
//  Seedkeeper
//
//  Created by Satochip on 20/09/2024.
//

import Foundation
import SwiftUI

//TODO: merge with BackupCongratsView?
struct BackupFailedView: View {
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
                
                SatoText(text: "failedInfoTtile", style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 16)
                
                SatoText(text: "failedInfoSubtitle", style: .SKStrongBodyDark)
                
                Spacer()
                
                // User inf during secret import to backup card
                if (cardState.backupMode == .initiateImportToBackup){
                    // TODO: provide more context and better instructions to user! + localization
                    // show export progression as it may require several nfc sessions
                    SatoText(text: "Failed to complete backup: \(cardState.backupError)", style: .SKStrongBodyDark)
                    
                    SatoText(text: "Secrets imported: \(cardState.importIndex) out of \(cardState.secretsForBackup.count) ", style: .SKStrongBodyDark)
                    Spacer()
                }
                
                Image("il_backup_congrats")//TODO: change image
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
                SatoText(text: "failedInfoTtile", style: .lightTitleDark)
            }
        }
    }
}
