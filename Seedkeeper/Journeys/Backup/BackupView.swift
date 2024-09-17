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
    case backupExportReady
    case initiateBackupExport
}

struct BackupView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    
    func getActionButtonTitle() -> String {
        switch cardState.mode {
        case .start:
            return String(localized: "start")
        case .pairBackupCard:
            return String(localized: "next")
        case .backupImport:
            return String(localized: "backupImportBtn")
        case .backupExportReady:
            return String(localized: "backupExportBtn")
        case .initiateBackupExport:
            return String(localized: "next")
        }
    }
    
    func getViewSubtitle() -> String {
        switch cardState.mode {
        case .start:
            return "backupStartSubtitle"
        case .pairBackupCard:
            return "backupPairBackupCardSubtitle"
        case .backupImport:
            return "backupImportSubtitle"
        case .backupExportReady:
            return "backupExportSubtitle"
        case .initiateBackupExport:
            return "backupInitiateExportSubtitle"
        }
    }
    
    func getIndicationImageName() -> String {
        switch cardState.mode {
        case .start:
            return "il_backup_master_backup"
        case .pairBackupCard:
            return "il_backup_backup"
        case .backupImport:
            return "il_backup_master"
        case .backupExportReady:
            return "il_backup_master_backup"
        case .initiateBackupExport:
            return "il_backup_backup"
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
                
                SatoText(text: getViewSubtitle(), style: .SKStrongBodyDark)
                
                Spacer()
                    
                Image(getIndicationImageName())
                    .resizable()
                    .frame(width: 315, height: 149)
                
                Spacer()
                    .frame(height: 16)
                
                SKButton(text: getActionButtonTitle(), style: .regular, horizontalPadding: 66, action: {
                    switch cardState.mode {
                    case .start:
                        cardState.mode = .pairBackupCard
                    case .pairBackupCard:
                        cardState.scanBackupCard()
                    case .backupImport:
                        //cardState.requestFetchSecretsForBackup()
                        cardState.requestExportSecretsForBackup()
                    case .backupExportReady:
                        cardState.mode = .initiateBackupExport
                    case .initiateBackupExport:
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
            cardState.resetStateForBackupCard(clearPin: true)
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
