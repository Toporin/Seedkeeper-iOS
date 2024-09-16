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
//    @State private var showPickerSheet = false
//    @State var phraseTypeOptions = PickerOptions(placeHolder: String(localized: "typeOfSecret"), items: GeneratorMode.self)
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
                
                // Use a dropdown menue to select secret type
//                SelectableCardInfoBox(mode: .dropdown(self.phraseTypeOptions), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { options in
//                    showPickerSheet = true
//                }
//                
//                Spacer().frame(height: 16)
                
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
                
                
                // next button for dropdown list
//                SKButton(text: String(localized: "next"), style: .regular, horizontalPadding: 66, action: {
//                    guard phraseTypeOptions.isItemSelected, let selectedOption = phraseTypeOptions.selectedOption else {
//                        return
//                    }
//
//                    homeNavigationPath.append(NavigationRoutes.generateGenerator(GeneratorModeNavData(generatorMode: selectedOption, secretCreationMode: secretCreationMode)))
//                })
                
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
//        .sheet(isPresented: $showPickerSheet) {
//            if #available(iOS 16.4, *) {
//                OptionSelectorView(pickerOptions: $phraseTypeOptions)
//                    .presentationDetents([.height(Dimensions.optionSelectorSheetHeight)])
//                    .presentationBackground(.ultraThinMaterial)
//            } else {
//                OptionSelectorView(pickerOptions: $phraseTypeOptions)
//                    .presentationDetents([.height(Dimensions.optionSelectorSheetHeight)])
//                    .background(Image("bg-glow-small")
//                        .resizable()
//                        .scaledToFill()
//                        .blur(radius: 10)
//                        .edgesIgnoringSafeArea(.all))
//            }
//        }
    }
}
