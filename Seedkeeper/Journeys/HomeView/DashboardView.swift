//
//  DashboardView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 04/05/2024.
//

import Foundation
import SwiftUI

struct DashboardView: View {
    @Binding var homeNavigationPath: NavigationPath
    @State var secretsList: [String] = ["secret1", "secret2"]
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 48)
            
            SatoText(text: "manageSecretsSubtitle", style: .SKStrongBodyDark)
            
            Spacer()
                .frame(height: 48)
            
            SatoText(text: "mySecretList", style: .SKStrongBodyDark)
            
            Spacer()
                .frame(height: 12)
            
            List {
                ForEach(secretsList, id: \.self) { secret in
                    SKSecretButton(secret: secret) {
                        homeNavigationPath.append(NavigationRoutes.showSecret(secret))
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowSeparator(.hidden)
                
                Button(action: {
                    homeNavigationPath.append(NavigationRoutes.addSecret)
                }) {
                    Image("ic_plus_circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46)
                .background(Colors.purpleBtn)
                .cornerRadius(20)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
            .background(Color.clear)
            
            Spacer()
        }
        .padding([.leading, .trailing], Dimensions.lateralPadding)
    }
}

struct SKSecretButton: View {
    let secret: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Spacer()
                    .frame(width: 12)
                
                Image("ic_leaf")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                
                Spacer()

                SatoText(text: secret, style: .SKStrongBodyLight)
                
                Spacer()

                Image("ic_info")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                
                Spacer()
                    .frame(width: 12)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46)
        .background(Colors.purpleBtn)
        .cornerRadius(20)
    }
}
