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
                    title: "Password", //String(localized: "generateASecret"),
                    iconName: "ic_magic_wand", // TODO: icon
                    iconWidth: 50,
                    iconHeight: 50,
                    backgroundColor: Colors.purpleBtn,
                    action: {
                        homeNavigationPath.append(NavigationRoutes.generateGenerator(GeneratorModeNavData(generatorMode: .password, secretCreationMode: secretCreationMode)))
                    },
                    forcedHeight: 100,
                    subTitle: String(localized: "generateASecretSubtitle") // TODO: txt
                )
                
                Spacer()
                    .frame(height: 24)
                
                MenuButton(
                    title: "Mnemonic", //String(localized: "generateASecret"), // TODO: localize
                    iconName: "ic_magic_wand", // TODO: icon
                    iconWidth: 50,
                    iconHeight: 50,
                    backgroundColor: Colors.purpleBtn,
                    action: {
                        homeNavigationPath.append(NavigationRoutes.generateGenerator(GeneratorModeNavData(generatorMode: .mnemonic, secretCreationMode: secretCreationMode)))
                    },
                    forcedHeight: 100,
                    subTitle: String(localized: "generateASecretSubtitle") // TODO: txt
                )
                
                Spacer()
                    .frame(height: 24)
                
                if (secretCreationMode == SecretCreationMode.manualImport){
                    MenuButton(
                        title: "Descriptor", //String(localized: "generateASecret"), // TODO: localize
                        iconName: "ic_magic_wand", // TODO: icon
                        iconWidth: 50,
                        iconHeight: 50,
                        backgroundColor: Colors.purpleBtn,
                        action: {
                            homeNavigationPath.append(NavigationRoutes.generateGenerator(GeneratorModeNavData(generatorMode: .descriptor, secretCreationMode: secretCreationMode)))
                        },
                        forcedHeight: 100,
                        subTitle: String(localized: "generateASecretSubtitle") // TODO: txt
                    )
                    
                    Spacer()
                        .frame(height: 24)
                }
                
                if (secretCreationMode == SecretCreationMode.manualImport){
                    MenuButton(
                        title: "Data", //String(localized: "generateASecret"), // TODO: localize
                        iconName: "ic_magic_wand", // TODO: icon
                        iconWidth: 50,
                        iconHeight: 50,
                        backgroundColor: Colors.purpleBtn,
                        action: {
                            homeNavigationPath.append(NavigationRoutes.generateGenerator(GeneratorModeNavData(generatorMode: .data, secretCreationMode: secretCreationMode)))
                        },
                        forcedHeight: 100,
                        subTitle: String(localized: "generateASecretSubtitle") // TODO: txt
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
