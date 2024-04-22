//
//  HomeView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import SwiftUI

enum NavigationRoutes: Hashable {
    case home
    case menu
    case settings
    case createPinCode
    case confirmPinCode(String)
}

struct HomeView: View {
    @State private var homeNavigationPath = NavigationPath()
        
    var body: some View {
        NavigationStack(path: $homeNavigationPath) {
            ZStack {
                Image("bg_glow")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    HeaderView(homeNavigationPath: $homeNavigationPath)
                 
                    Spacer()
                    
                    Spacer().frame(height: 16)
                }
                
                //if condition for scan visibility {
                    EmptyScanStateOverlay(homeNavigationPath: $homeNavigationPath)
                //}
            }
            .navigationDestination(for: NavigationRoutes.self) { route in
                switch route {
                case .home:
                    HomeView()
                case .menu:
                    MenuView(homeNavigationPath: $homeNavigationPath)
                case .settings:
                    SettingsView(homeNavigationPath: $homeNavigationPath)
                case .createPinCode:
                    CreatePinCodeView(homeNavigationPath: $homeNavigationPath)
                case .confirmPinCode(let pinCodeToValidate):
                    ConfirmPinCodeView(homeNavigationPath: $homeNavigationPath, pinCodeToValidate: pinCodeToValidate)
                }
            }
        }
    }
}

