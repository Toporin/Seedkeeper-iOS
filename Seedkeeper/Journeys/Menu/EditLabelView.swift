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
    
    @State private var labelText: String = ""
    
    var isEditButtonEnabled: Bool { //TODO: use?
        return labelText.count < 64
    }
    
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
                
                Spacer()
                
                SKButton(text: String(localized: "editLabelButton"), style: .regular, horizontalPadding: 66, isEnabled: true, action: {
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

