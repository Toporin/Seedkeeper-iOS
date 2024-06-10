//
//  SetupFaceIdView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 21/04/2024.
//

import Foundation
import SwiftUI

struct SetupFaceIdView: View {
    // MARK: - Properties
    @Binding var homeNavigationPath: NavigationPath
    var pinCode: String
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Spacer()
                
                SatoText(text: "unlockWithFaceIdTitle", style: .title)
                
                Spacer().frame(height: 10)
                
                SatoText(text: "unlockWithFaceIdSubtitle", style: .SKMenuItemTitle)
                
                Spacer().frame(height: 24)
                
                Image("il_face_id")
                    .resizable()
                    .frame(width: 100, height: 100)
                
                Spacer()
                
                Button(action: {
                    homeNavigationPath = .init()
                }) {
                    SatoText(text: "notNow", style: .SKMenuItemTitle)
                }
                
                Spacer()
                    .frame(height: 16)
                
                SKButton(text: String(localized: "enable"), style: .regular, horizontalPadding: 66, action: {
                    // TODO: trigger faceId logic
                })
                
                Spacer().frame(height: 16)

            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            homeNavigationPath = .init()
        }) {
            Image("ic_back_dark")
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                SatoText(text: "setup", style: .lightTitleDark)
            }
        }
    }
}
