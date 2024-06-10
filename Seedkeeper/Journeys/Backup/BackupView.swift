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
    case pair
    case backupImport
    case backupExport
}

struct BackupView: View {
    // MARK: - Properties
    @Binding var homeNavigationPath: NavigationPath
    @State var mode: BackupMode = .start
    
    func getActionButtonTitle() -> String {
        switch mode {
        case .start:
            return "start"
        case .pair:
            return "next"
        case .backupImport:
            return "scan my seedkeeper"
        case .backupExport:
            return "next"
        }
    }
    
    func getIndicationImageName() -> String {
        switch mode {
        case .start:
            return "il_backup_master_backup"
        case .pair:
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
                    switch mode {
                    case .start:
                        mode = .pair
                    case .pair:
                        break
                    case .backupImport:
                        break
                    case .backupExport:
                        break
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
