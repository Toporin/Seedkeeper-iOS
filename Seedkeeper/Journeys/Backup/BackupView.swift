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
    case backupExportFromMaster
    case backupExportReady
    case initiateImportToBackup
}

struct BackupView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    
    @State private var showProgressBar: Bool = false

    
    func getActionButtonTitle() -> String {
        switch cardState.backupMode {
        case .start:
            return String(localized: "start")
        case .pairBackupCard:
            return String(localized: "next")
        case .backupExportFromMaster:
            return String(localized: "backupImportBtn")
        case .backupExportReady:
            return String(localized: "backupExportBtn")
        case .initiateImportToBackup:
            return String(localized: "next")
        }
    }
    
    func getViewSubtitle() -> String {
        switch cardState.backupMode {
        case .start:
            return "backupStartSubtitle"
        case .pairBackupCard:
            return "backupPairBackupCardSubtitle"
        case .backupExportFromMaster:
            return "backupImportSubtitle"
        case .backupExportReady:
            return "backupExportSubtitle"
        case .initiateImportToBackup:
            return "backupInitiateExportSubtitle"
        }
    }
    
    func getIndicationImageName() -> String {
        switch cardState.backupMode {
        case .start:
            return "il_backup_master_backup"
        case .pairBackupCard:
            return "il_backup_backup"
        case .backupExportFromMaster:
            return "il_backup_master"
        case .backupExportReady:
            return "il_backup_master_backup"
        case .initiateImportToBackup:
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
                
                // User info when exporting encrypted secrets
                if (cardState.backupMode == .backupExportFromMaster){
                    if (cardState.secretHeadersForBackup.count > 30){
                        SatoText(text: "backupMultipleNFCSessionNote", style: .SKStrongBodyDark)
                    }
                    // show export progression as it may require several nfc sessions
                    //SatoText(text: String(localized: "backupSecretsExported") + "\(cardState.exportIndex)/\(cardState.secretHeadersForBackup.count) ", style: .SKStrongBodyDark)
                    
                    if showProgressBar {
                        ProgressView(String(localized: "backupExportingProgressBar"), value: Double(cardState.exportIndex), total: Double(cardState.secretHeadersForBackup.count))
                        Spacer()
                    }
                }
               
                // User info after encrypted secrets
                else if (cardState.backupMode == .backupExportReady){
                    // show export progression as it may require several nfc sessions
                    SatoText(text: String(localized: "numberSecretsToBackup") + "\(cardState.secretsForBackup.count)", style: .SKStrongBodyDark)
                    //SatoText(text: String(localized: "numberSkippedSecrets") + "\(cardState.numberSkippedSecrets)", style: .SKStrongBodyDark)
                    
                    Spacer()
                }
                
                // User inf during secret import to backup card
                else if (cardState.backupMode == .initiateImportToBackup){
                    // TODO: provide more context and better instructions to user! + localization
                    // show export progression as it may require several nfc sessions
                    
                    //SatoText(text: String(localized: "backupSecretsImported") + "\(cardState.importIndex)/\(cardState.secretsForBackup.count) ", style: .SKStrongBodyDark)
                    
                    if showProgressBar {
                        ProgressView(String(localized: "backupImportingProgressBar"), value: Double(cardState.importIndex), total: Double(cardState.secretsForBackup.count))
                        
                        Spacer()
                    }
                }
                
                Image(getIndicationImageName())
                    .resizable()
                    .frame(width: 315, height: 149)
                
                Spacer()
                    .frame(height: 16)
                
                SKButton(text: getActionButtonTitle(), style: .regular, horizontalPadding: 66, action: {
                    switch cardState.backupMode {
                    case .start:
                        // reset var & empty the list of secrets to export
                        cardState.secretsForBackup.removeAll()
                        cardState.importIndex = 0
                        cardState.exportIndex = 0
                        cardState.backupMode = .pairBackupCard
                        showProgressBar = false
                    case .pairBackupCard:
                        homeNavigationPath.append(NavigationRoutes.pinCode(.continueBackupFlow))
                    case .backupExportFromMaster:
                        showProgressBar = true
                        cardState.requestExportSecretsForBackup()
                    case .backupExportReady:
                        showProgressBar = false
                        cardState.backupMode = .initiateImportToBackup
                    case .initiateImportToBackup:
                        showProgressBar = true
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
