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
                
                SatoText(text: "generateSecret", style: .SKStrongBodyDark)
                
                Spacer().frame(height: 16)
                
                SatoText(text: "generateSecretInfoSubtitle", style: .SKStrongBodyDark)
                
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
        }
    }
}

struct OptionSelectorView<T: CaseIterable & Hashable & HumanReadable>: View {
    @Binding var pickerOptions: PickerOptions<T>
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Colors.purpleBtn.edgesIgnoringSafeArea(.all)
            
            VStack {
                List(pickerOptions.items, id: \.self) { item in
                    Button(action: {
                        pickerOptions.selectedOption = item
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(item.humanReadableName())
                            .font(.headline)
                            .foregroundColor(.white)
                            .background(Color.clear)
                    }
                    .listRowBackground(Color.clear)
                }
                .padding(20)
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }
        }
    }
}

protocol HumanReadable {
    func humanReadableName() -> String
}

struct PickerOptions<T: CaseIterable & Hashable & HumanReadable> {
    let placeHolder: String
    let items: [T]
    var selectedOption: T?
    
    var isItemSelected: Bool {
        return selectedOption != nil
    }
    
    init(placeHolder: String, items: T.Type, selectedOption: T? = nil) {
        self.placeHolder = placeHolder
        self.items = Array(items.allCases)
        self.selectedOption = selectedOption
    }
}
