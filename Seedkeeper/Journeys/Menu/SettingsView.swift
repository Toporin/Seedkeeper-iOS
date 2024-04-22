//
//  SettingsView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    struct dimensions {
        static let verticalGroupSeparator: CGFloat = 24
        static let verticalInsideGroupSeparator: CGFloat = 5
    }
    // MARK: - Properties
    @Binding var homeNavigationPath: NavigationPath
    
    @State var starterIntroIsOn: Bool = false
    @State var expertModeIsOn: Bool = false
    @State var debugModeIsOn: Bool = false

    // MARK: - Literals
    let title = "settings"
    let showLogsButtonTitle = String(localized: "settings.showLogs")

    var body: some View {

            ZStack {
                Image("bg_glow")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                        .frame(height: 16)
                    
                    Image("il_settings")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 139)
                    
                    Spacer()
                        .frame(height: SettingsView.dimensions.verticalGroupSeparator)
                    
                    SatoText(text: "settings.showIntroduction", style: .SKMenuItemTitle)
                    Spacer()
                        .frame(height: SettingsView.dimensions.verticalInsideGroupSeparator)
                    SatoText(text: "settings.showIntroductionSubtitle", style: .SKMenuItemSubtitle)
                    Spacer()
                        .frame(height: SettingsView.dimensions.verticalInsideGroupSeparator)
                    SettingsToggle(title: "settings.toggle.starterIntro",
                                   backgroundColor: Colors.lightMenuButton,
                                   isOn: $starterIntroIsOn,
                                   onToggle: { newValue in
                        
                    })
                    
                    Spacer()
                        .frame(height: SettingsView.dimensions.verticalGroupSeparator)
                    
                    SatoText(text: "settings.expertMode", style: .SKMenuItemTitle)
                    Spacer()
                        .frame(height: SettingsView.dimensions.verticalInsideGroupSeparator)
                    SatoText(text: "settings.expertModeSubtitle", style: .SKMenuItemSubtitle)
                    Spacer()
                        .frame(height: SettingsView.dimensions.verticalInsideGroupSeparator)
                    SettingsToggle(title: "settings.expertMode",
                                   backgroundColor: Colors.lightMenuButton,
                                   isOn: $expertModeIsOn,
                                   onToggle: { newValue in
                        
                    })
                    
                    Spacer()
                        .frame(height: SettingsView.dimensions.verticalGroupSeparator)
                    
                    SatoText(text: "settings.debugMode", style: .SKMenuItemTitle)
                    Spacer()
                        .frame(height: SettingsView.dimensions.verticalInsideGroupSeparator)
                    SatoText(text: "settings.debugModeSubtitle", style: .SKMenuItemSubtitle)
                    Spacer()
                        .frame(height: SettingsView.dimensions.verticalInsideGroupSeparator)
                    SettingsToggle(title: "settings.debugMode",
                                   backgroundColor: Colors.lightMenuButton,
                                   isOn: $debugModeIsOn,
                                   onToggle: { newValue in
                        
                    })
                    
                    Spacer()
                        .frame(height: SettingsView.dimensions.verticalGroupSeparator)
                    
                    SKButton(text: showLogsButtonTitle, style: .inform) {}
                    
                    Spacer()
                }
                .padding([.leading, .trailing], 20)
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
                    SatoText(text: title, style: .lightTitleDark)
                }
            }
    }
}

struct SettingsToggle: View {
    let title: String
    let backgroundColor: Color
    @Binding var isOn: Bool
    var onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Toggle(isOn: $isOn){
                SatoText(text: title, style: .subtitleBold)
            }
            .toggleStyle(SKToggleStyle(onColor: Colors.ledGreen, offColor: Colors.darkMenuButton, thumbColor: .gray))
            .onChange(of: isOn) { newValue in
                onToggle(newValue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 55, maxHeight: 55)
        .background(backgroundColor)
        .cornerRadius(20)
    }
}

struct SKToggleStyle: ToggleStyle {

    var onColor: Color
    var offColor: Color
    var thumbColor: Color

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            configuration.label
                .font(.body)
            Spacer()
            RoundedRectangle(cornerRadius: 16, style: .circular)
                .fill(configuration.isOn ? onColor : offColor)
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(thumbColor)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                )
                .onTapGesture {
                    withAnimation(.smooth(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}
