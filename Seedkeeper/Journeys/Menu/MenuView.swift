//
//  MenuView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import Foundation
import SwiftUI

enum SatochipURL: String {
    case howToUse = "https://satochip.io/setup-use-satodime-on-mobile/"
    case terms = "https://satochip.io/terms-of-service/"
    case privacy = "https://satochip.io/privacy-policy/"
    case products = "https://satochip.io/shop/"

    var url: URL? {
        return URL(string: self.rawValue)
    }
}

struct MenuView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    
    // MARK: - Helpers
    func openURL(_ satochipURL: SatochipURL) {
        guard let url = satochipURL.url else {
            print("Invalid URL")
            return
        }
        UIApplication.shared.open(url)
    }
    
    // MARK: - View
    var body: some View {
        ZStack {
            
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                    .frame(height: 29)
                
                Image("ic_sk_logo_dark")
                    .frame(width: 250, height: 116)
                
                Spacer()
                    .frame(height: 30)
                
                GeometryReader { geometry in
                    HStack(spacing: 10) {
                        
                        MenuButton(
                            title: String(localized: "cardInfo"),
                            iconName: "ic_credit_card",
                            iconWidth: 34, iconHeight: 34,
                            backgroundColor: Colors.darkMenuButton,
                            action: {
                                if let _ = cardState.cardStatus {
                                    self.homeNavigationPath.append(NavigationRoutes.cardInfo)
                                }
                            },
                            forcedHeight: 90
                        )
                        .frame(width: geometry.size.width * 1.0 - 15)
                        
                    }
                    .padding([.horizontal], 10)
                }
                .frame(height: 90)
                
                Spacer()
                    .frame(height: 10)
                
                GeometryReader { geometry in
                    HStack(spacing: 10) {
                        
                        // BACKUP
                        MenuButton(
                            title: String(localized: "makeABackup"),
                            iconName: "ic_backup",
                            iconWidth: 34,
                            iconHeight: 34,
                            backgroundColor: Colors.lightMenuButton,
                            action: {
                                self.homeNavigationPath.append(NavigationRoutes.backup)
                            },
                            forcedHeight: 108
                        )
                        .frame(width: geometry.size.width * 0.55 - 15)
                        
                        // SETTINGS
                        MenuButton(
                            title: String(localized: "settings"),
                            iconName: "ic_settings",
                            iconWidth: 27,
                            iconHeight: 27,
                            backgroundColor: Colors.darkMenuButton,
                            action: {
                                self.homeNavigationPath.append(NavigationRoutes.settings)
                            },
                            forcedHeight: 108
                        )
                        .frame(width: geometry.size.width * 0.45 - 15)
                    }
                    .padding([.horizontal], 10)
                }
                .frame(height: 108)
                
                Spacer()
                    .frame(height: 15)
                
                GeometryReader { geometry in
                    HStack(spacing: 10) {
                        
                        MenuButton(
                            title: String(localized: "howToUse"),
                            iconName: "ic_howto",
                            iconWidth: 34, iconHeight: 34,
                            backgroundColor: Colors.lightMenuButton,
                            action: {
                                
                            },
                            forcedHeight: 58
                        )
                        .frame(width: geometry.size.width * 1.0 - 15)
                        
                    }
                    .padding([.horizontal], 10)
                }
                .frame(height: 58)
                
                Spacer()
                    .frame(height: 10)
                
                HStack(spacing: 10) {
                    SmallMenuButton(
                        text: String(localized: "termsOfService"),
                        backgroundColor: Colors.darkMenuButton,
                        action: {
                            self.openURL(.terms)
                        }
                    )
                    
                    SmallMenuButton(
                        text: String(localized: "privacyPolicy"),
                        backgroundColor: Colors.darkMenuButton,
                        action: {
                            self.openURL(.privacy)
                        }
                    )
                }
                .padding([.horizontal], 10)
                
                Spacer()
                
                Rectangle()
                    .frame(width: 108, height: 2)
                    .foregroundColor(Colors.menuSeparator)
                
                Spacer()
                
                ProductButton {
                    self.openURL(.products)
                }
                .frame(maxWidth: .infinity)
                .padding([.horizontal], 10)
                
                Spacer()
                    .frame(height: 29)
                
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            homeNavigationPath.removeLast()
        }) {
            Image("ic_back_dark")
        })
    }
}

struct ContentView: View {
    @Binding var shouldShowSettings: Bool
    
    var body: some View {
        NavigationStack {
            Text("ContentView")
            Button(action: {
                shouldShowSettings = false
            }) {
                Text("Dismiss me")
            }
        }
    }
}

struct MenuButton: View {
    let title: String
    let iconName: String
    let iconWidth: CGFloat
    let iconHeight: CGFloat
    let backgroundColor: Color
    let action: () -> Void
    var forcedHeight: CGFloat = 120
    var subTitle: String? = nil

    var body: some View {
        Button(action: action) {
            Group {
                if forcedHeight < 60 {
                    HStack {
                        Text(title)
                            .foregroundColor(.white)
                            .font(.headline)
                            .lineLimit(2)
                            .padding([.leading, .trailing])
                        Spacer()
                        Image(iconName)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .frame(width: iconWidth, height: iconHeight)
                            .padding([.trailing])
                    }
                } else {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(title)
                                .foregroundColor(.white)
                                .font(.headline)
                                .lineLimit(2)
                                .padding([.top, .leading, .trailing])
                            Spacer()
                        }
                        Spacer()
                        HStack {
                            if let subTitle = subTitle {
                                Text(subTitle)
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .padding([.leading, .trailing])
                            }
                            Spacer()
                            Image(iconName)
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(.white)
                                .frame(width: iconWidth, height: iconHeight)
                                .padding([.trailing, .bottom])
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: forcedHeight, maxHeight: forcedHeight)
            .background(backgroundColor)
            .cornerRadius(20)
        }
    }
}

struct SmallMenuButton: View {
    let text: String
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SatoText(text: text, style: .extraLightSubtitle)
                .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 57)
        .background(backgroundColor)
        .cornerRadius(20)
    }
}

struct ProductButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Image("bg_btn_product")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 155)
                    .cornerRadius(20)
                    .clipped()

                VStack {
                    HStack {
                        Text(String(localized: "allOurProducts"))
                            .font(
                                Font.custom("Outfit", size: 20)
                                    .weight(.medium)
                            )
                            .foregroundColor(.white)
                            .padding([.top, .leading])
                        Spacer()
                    }
                    Spacer()
                }.frame(height: 155)
                
            }.frame(height: 155)
        }
    }
}

