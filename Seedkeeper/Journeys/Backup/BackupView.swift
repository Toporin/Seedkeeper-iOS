//
//  BackupView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 23/05/2024.
//

import Foundation
import SwiftUI

enum BackupMode {
    case start
    case pairBackupCard
    case backupImport
    case backupExport
}

struct BackupView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    
    func getActionButtonTitle() -> String {
        switch cardState.mode {
        case .start:
            return "start"
        case .pairBackupCard:
            return "scan my backup card"
        case .backupImport:
            return "scan my master card again"
        case .backupExport:
            return "backup"
        }
    }
    
    func getIndicationImageName() -> String {
        switch cardState.mode {
        case .start:
            return "il_backup_master_backup"
        case .pairBackupCard:
            return "il_backup_backup"
        case .backupImport:
            return "il_backup_master_backup"
        case .backupExport:
            return "il_backup_master_backup"
        }
    }
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Spacer()
                    .frame(height: 60)
                
                SatoText(text: "backupInfoSubtitle", style: .SKStrongBodyDark)
                
                Spacer()
                    
                Image(getIndicationImageName())
                    .resizable()
                    .frame(width: 315, height: 149)
                
                Spacer()
                
                Button(action: {
                    homeNavigationPath.removeLast()
                }) {
                    SatoText(text: "back", style: .SKMenuItemTitle)
                }
                
                Spacer()
                    .frame(height: 16)
                
                SKButton(text: getActionButtonTitle(), style: .regular, horizontalPadding: 66, action: {
                    switch cardState.mode {
                    case .start:
                        cardState.mode = .pairBackupCard
                    case .pairBackupCard:
                        cardState.scanBackupCard()
                    case .backupImport:
                        cardState.requestFetchSecretsForBackup()
                    case .backupExport:
                        cardState.requestImportSecretsToBackupCard()
                    }
                })
                
                Spacer().frame(height: 16)

            }
            .padding([.leading, .trailing], Dimensions.lateralPadding)
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
                SatoText(text: "backupViewTitle", style: .lightTitleDark)
            }
        }
    }
}
