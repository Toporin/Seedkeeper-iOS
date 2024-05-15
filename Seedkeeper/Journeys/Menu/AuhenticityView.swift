//
//  AuhenticityView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 02/05/2024.
//

import Foundation
import SwiftUI

struct AuthenticityView: View {
    // MARK: - Properties
    @Binding var homeNavigationPath: NavigationPath
    @State var shouldShowDeviceInfo = false
    @State var shouldShowSubcaInfo = false

    // MARK: - Body
    var body: some View {
        ZStack {
            
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            ScrollView{
                VStack {
                    Spacer()
                        .frame(height: 29)
                    
                    Image("logo_seedkeeper")
                        .resizable()
                        .frame(width: 250, height: 116)
                    
                    Spacer()
                        .frame(height: 22)
                    
                    // If condition to display authenticity state
                    Image("il_not_authentic")
                        .resizable()
                        .frame(width: 150, height: 150)
                    Spacer()
                        .frame(height: 38)
                    SatoText(text: "authenticationFailedText", style: .SKStrongBodyDark)
                    
                    Spacer()
                        .frame(height: 22)
                    
                    // DEVICE CERT
                    CardInfoBox(
                        text: self.shouldShowDeviceInfo ? "hideDeviceCert" : "showDeviceCert",
                        backgroundColor: Colors.ledRed)
                    {
                        self.shouldShowDeviceInfo.toggle()
                    }
                        .padding([.leading, .trailing], 57)
                    
                    if self.shouldShowDeviceInfo {
                        VStack {
                            
                            HStack {
                                Spacer()
                                
                                Image(systemName: "square.on.square")
                                    .frame(width: 15, height: 15)
                                    .foregroundColor(.black)
                                    .onTapGesture(count: 1) {
                                        // Copy to clipboard
                                    }
                            }
                            
                            SatoText(text: "Pubkey: \("(none)")",style: .SKStrongBodyDark)
                            
                            SatoText(text: "PEM: \("(none)")",style: .SKStrongBodyDark)
                        }
                        .padding(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Colors.ledRed, lineWidth: 4)
                                .padding(15)
                        )
                    }
                    
                    Spacer()
                        .frame(height: 33)
                    
                    CardInfoBox(
                        text: self.shouldShowSubcaInfo ? "hideSubcaCert" : "showSubcaCert",
                        backgroundColor: Colors.ledRed)
                    {
                        self.shouldShowSubcaInfo.toggle()
                    }
                        .padding([.leading, .trailing], 57)
                    
                    if self.shouldShowSubcaInfo {
                        VStack {
                            HStack {
                                Spacer()
                                
                                Image(systemName: "square.on.square")
                                    .frame(width: 15, height: 15)
                                    .foregroundColor(.black)
                                    .onTapGesture(count: 1) {
                                        // Copy to clipboard
                                    }
                            }
                            
                            SatoText(text: "Pubkey: \("(none)")",style: .SKStrongBodyDark)
                            
                            SatoText(text: "PEM: \("(none)")",style: .SKStrongBodyDark)

                        }
                        .padding(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Colors.ledRed, lineWidth: 4)
                                .padding(15)
                        )
                    }
                    
                }
            }
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
                SatoText(text: "", style: .lightTitleDark)
            }
        }
    }
}

