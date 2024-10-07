//
//  GenerateSecretView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 07/05/2024.
//

import Foundation
import SwiftUI

struct GenerateSecretTypeView: View {
    // MARK: - Properties
    @Binding var homeNavigationPath: NavigationPath
    var secretCreationMode: SecretCreationMode
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer().frame(height: 60)
                
                SatoText(text: secretCreationMode == .generate ? "generateSecret" : "importASecret", style: .SKStrongBodyDark)
                
                Spacer().frame(height: 16)
                
                SatoText(text: secretCreationMode == .generate ? "generateSecretInfoSubtitle" : "importASecretSubtitle", style: .SKStrongBodyDark)
                
                Spacer().frame(height: 16)
                
                // Use buttons
                MenuButton(
                    title: String(localized: "passwordTitle"),
                    iconName: "ic_3DotsUnderlined",
                    iconWidth: 50,
                    iconHeight: 50,
                    backgroundColor: Colors.purpleBtn,
                    action: {
                        homeNavigationPath.append(NavigationRoutes.generateGenerator(GeneratorModeNavData(generatorMode: .password, secretCreationMode: secretCreationMode)))
                    },
                    forcedHeight: 100,
                    subTitle: String(localized: "passwordDescription")
                )
                
                Spacer()
                    .frame(height: 24)
                
                MenuButton(
                    title: String(localized: "mnemonicTitle"),
                    iconName: "ic_leaf",
                    iconWidth: 50,
                    iconHeight: 50,
                    backgroundColor: Colors.purpleBtn,
                    action: {
                        homeNavigationPath.append(NavigationRoutes.generateGenerator(GeneratorModeNavData(generatorMode: .mnemonic, secretCreationMode: secretCreationMode)))
                    },
                    forcedHeight: 100,
                    subTitle: String(localized: "mnemonicDescription")
                )
                
                Spacer()
                    .frame(height: 24)
                
                if (secretCreationMode == SecretCreationMode.manualImport){
                    MenuButton(
                        title: String(localized: "descriptorTitle"),
                        iconName: "ic_descriptor_svg",
                        iconWidth: 50,
                        iconHeight: 50,
                        backgroundColor: Colors.purpleBtn,
                        action: {
                            homeNavigationPath.append(NavigationRoutes.generateGenerator(GeneratorModeNavData(generatorMode: .descriptor, secretCreationMode: secretCreationMode)))
                        },
                        forcedHeight: 100,
                        subTitle: String(localized: "descriptorDescription")
                    )
                    
                    Spacer()
                        .frame(height: 24)
                }
                
                if (secretCreationMode == SecretCreationMode.manualImport){
                    MenuButton(
                        title: String(localized: "dataTitle"),
                        iconName: "ic_data_svg",
                        iconWidth: 50,
                        iconHeight: 50,
                        backgroundColor: Colors.purpleBtn,
                        action: {
                            homeNavigationPath.append(NavigationRoutes.generateGenerator(GeneratorModeNavData(generatorMode: .data, secretCreationMode: secretCreationMode)))
                        },
                        forcedHeight: 100,
                        subTitle: String(localized: "dataDescription")
                    )
                    
                    Spacer()
                        .frame(height: 24)
                }
                
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
                SatoText(text: secretCreationMode == .manualImport ? "importSecret" : "generateSecret", style: .lightTitleDark)
            }
        }
    }
}
