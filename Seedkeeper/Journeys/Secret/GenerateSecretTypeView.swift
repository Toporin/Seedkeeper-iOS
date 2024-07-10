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
    @State private var showPickerSheet = false
    @State var phraseTypeOptions = PickerOptions(placeHolder: String(localized: "typeOfSecret"), items: GeneratorMode.self)
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
                
                SelectableCardInfoBox(mode: .dropdown(self.phraseTypeOptions), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { options in
                    showPickerSheet = true
                }

                Spacer()
                
                Button(action: {
                    homeNavigationPath.removeLast()
                }) {
                    SatoText(text: "back", style: .SKMenuItemTitle)
                }
                
                Spacer().frame(height: 16)
                
                SKButton(text: String(localized: "next"), style: .regular, horizontalPadding: 66, action: {
                    guard phraseTypeOptions.isItemSelected, let selectedOption = phraseTypeOptions.selectedOption else {
                        return
                    }

                    homeNavigationPath.append(NavigationRoutes.generateGenerator(GeneratorModeNavData(generatorMode: selectedOption, secretCreationMode: secretCreationMode)))
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
                SatoText(text: secretCreationMode == .manualImport ? "importSecret" : "generateSecret", style: .lightTitleDark)
            }
        }
        .sheet(isPresented: $showPickerSheet) {
            OptionSelectorView(pickerOptions: $phraseTypeOptions)
                .presentationDetents([.height(Dimensions.optionSelectorSheetHeight)])
                .presentationBackground(.ultraThinMaterial)
        }
    }
}
