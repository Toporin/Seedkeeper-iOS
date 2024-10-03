//
//  SetLabelView.swift
//  Seedkeeper
//
//  Created by Satochip on 30/09/2024.
//

import Foundation
import SwiftUI



struct EditLabelView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    @State var currentLabel: String
    
    @State private var msgError: SecretImportWizardError? = nil
    
    @State private var labelText: String = ""
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                
                SatoText(text: "editLabelTitle", style: .title)
                
//                Spacer().frame(height: 10)
//                
//                SatoText(text: "editLabelSubtitle", style: .SKMenuItemTitle)
                
                Spacer().frame(height: 24)
                
                EditableCardInfoBox(mode: .text(currentLabel), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { labelTextResult in
                    if case .text(let customLabelText) = labelTextResult {
                        labelText = customLabelText
                    }
                }
                
                if let msgError = msgError {
                    Spacer()
                        .frame(height: 16)
                    
                    Text(msgError.localizedString())
                        .font(.custom("Roboto-Regular", size: 12))
                        .foregroundColor(Colors.ledRed)
                }
                
                Spacer()
                
                SKButton(text: String(localized: "editLabelButton"), 
                         style: .regular, horizontalPadding: 66,
                         isEnabled: true,
                         action: {
                    
                    guard labelText.utf8.count <= Constants.MAX_CARD_LABEL_SIZE else {
                        msgError = .cardLabelTooLong
                        return
                    }
                    self.cardState.requestSetCardLabel(label: labelText)
                    }
                )
                
                Spacer().frame(height: 16)
            }
            .padding([.leading, .trailing], 32)
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
                SatoText(text: "editLabelTitle", style: .lightTitleDark)
            }
        }
    }
}

