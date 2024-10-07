//
//  AddSecretView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 04/05/2024.
//

import Foundation
import SwiftUI

struct AddSecretView: View {
    // MARK: - Properties
    @Binding var homeNavigationPath: NavigationPath
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Spacer()
                    .frame(height: 60)
                
                SatoText(text: "addSecretSubtitle", style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 60)
                
                MenuButton(
                    title: String(localized: "generateASecret"),
                    iconName: "ic_magic_wand",
                    iconWidth: 50,
                    iconHeight: 50,
                    backgroundColor: Colors.purpleBtn,
                    action: {
                        homeNavigationPath.append(NavigationRoutes.generateSecretType(.generate))
                    },
                    forcedHeight: 100,
                    subTitle: String(localized: "generateASecretSubtitle")
                )
                
                Spacer()
                    .frame(height: 24)
                
                MenuButton(
                    title: String(localized: "importASecret"),
                    iconName: "ic_import",
                    iconWidth: 50,
                    iconHeight: 50,
                    backgroundColor: Colors.lightMenuButton,
                    action: {
                        homeNavigationPath.append(NavigationRoutes.generateSecretType(.manualImport))
                    },
                    forcedHeight: 100,
                    subTitle: String(localized: "importASecretSubtitle")
                )
                
                Spacer()
                    
                MenuButton(
                    title: String(localized: "howToUse"),
                    iconName: "ic_questionmark",
                    iconWidth: 40,
                    iconHeight: 40,
                    backgroundColor: Colors.lightMenuButton,
                    action: {
                        if let url = SatochipURL.urlHowToUse.url {
                            UIApplication.shared.open(url)
                        }
                    },
                    forcedHeight: 53
                )
                
                Spacer()
                    .frame(height: 60)

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
                SatoText(text: "addSecretViewTitle", style: .lightTitleDark)
            }
        }
    }
}
