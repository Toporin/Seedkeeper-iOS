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
    case createPinCode(PinCodeNavigationData)
    case confirmPinCode(PinCodeNavigationData)
    case setupFaceId(String)
    case logs
    case cardInfo
    case authenticity
    case editPinCode
    case addSecret
    case showSecret(String)
    case generateSecret
    case generateMnemonic
    case generateSuccess
}

struct HomeView: View {
    @State private var homeNavigationPath = NavigationPath()
    @State private var isCardScanned = false
    @Environment(\.managedObjectContext) var managedObjectContext
        
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
                    
                    if isCardScanned {
                        DashboardView(homeNavigationPath: $homeNavigationPath)
                    } else {
                        EmptyScanStateOverlay(homeNavigationPath: $homeNavigationPath, isCardScanned: $isCardScanned)
                    }
                }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .navigationDestination(for: NavigationRoutes.self) { route in
                switch route {
                case .home:
                    HomeView()
                case .menu:
                    MenuView(homeNavigationPath: $homeNavigationPath)
                case .settings:
                    SettingsView(homeNavigationPath: $homeNavigationPath)
                case .createPinCode:
                    CreatePinCodeView(homeNavigationPath: $homeNavigationPath, pinCodeNavigationData: PinCodeNavigationData(mode: .createPinCode, pinCode: nil))
                case .confirmPinCode(let pinCodeNavigationData):
                    ConfirmPinCodeView(homeNavigationPath: $homeNavigationPath, pinCodeNavigationData: pinCodeNavigationData)
                case .setupFaceId(let pinCode):
                    SetupFaceIdView(homeNavigationPath: $homeNavigationPath, pinCode: pinCode)
                case .logs:
                    LogsView(homeNavigationPath: $homeNavigationPath)
                case .cardInfo:
                    CardInfoView(homeNavigationPath: $homeNavigationPath)
                case .authenticity:
                    AuthenticityView(homeNavigationPath: $homeNavigationPath)
                case .editPinCode:
                    CreatePinCodeView(homeNavigationPath: $homeNavigationPath, pinCodeNavigationData: PinCodeNavigationData(mode: .updatePinCode, pinCode: nil))
                case .addSecret:
                    AddSecretView(homeNavigationPath: $homeNavigationPath)
                case .showSecret(let secret):
                    ShowSecretView(homeNavigationPath: $homeNavigationPath, secret: secret)
                case .generateSecret:
                    GenerateSecretView(homeNavigationPath: $homeNavigationPath)
                case .generateMnemonic:
                    GenerateMnemonicView(homeNavigationPath: $homeNavigationPath)
                case .generateSuccess:
                    GenerateSuccessView(homeNavigationPath: $homeNavigationPath)
                }
            }
        }
        .onAppear {
            // Can be used to test logging
            // managedObjectContext.saveLogEntry(log: LogModel(type: .info, message: "Home view loaded"))
        }
    }
}
