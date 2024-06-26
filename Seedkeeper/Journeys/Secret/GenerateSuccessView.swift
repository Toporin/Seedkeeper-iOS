//
//  GenerateSuccessView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 09/05/2024.
//

import SwiftUI

struct GenerateSuccessView: View {
    // MARK: - Properties
    @Binding var homeNavigationPath: NavigationPath
    @State var secretLabel: String
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                Spacer()
                    .frame(height: 60)
                
                SatoText(text: "congrats", style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 16)
                
                SatoText(text: "generateSecretSuccessInfoSubtitle", style: .SKStrongBodyDark)
                
                Spacer()
                    .frame(height: 30)
                
                Text(secretLabel)
                    .font(.custom("OpenSans-Regular", size: 16))
                    .lineSpacing(24)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 33, maxHeight: 33)
                    .background(Colors.purpleBtn.opacity(0.5))
                    .cornerRadius(20)
                
                Spacer()
                    .frame(height: 30)
                
                Image("il_vault")
                    .resizable()
                    .frame(width: 225, height: 225)
                
                Spacer()
                
                SKButton(text: String(localized: "home"), style: .regular, horizontalPadding: 66, action: {
                    homeNavigationPath = .init()
                })
                
                Spacer().frame(height: 16)

            }
            .padding([.leading, .trailing], Dimensions.lateralPadding)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                SatoText(text: "generateSecretViewTitle", style: .lightTitleDark)
            }
        }
    }
}
