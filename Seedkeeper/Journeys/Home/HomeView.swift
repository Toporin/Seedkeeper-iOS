//
//  HomeView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import SwiftUI

enum ActionAfterPin {
    case rescanCard
}

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
    case pinCode(ActionAfterPin)
    case addSecret
    case showSecret(SeedkeeperSecretHeaderDto)
    case generateSecretType
    case generateGenerator(GeneratorMode)
    case generateSuccess(String)
    case backup
}

struct HomeView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var cardState: CardState
    
    private var isCardScanned: Bool {
        return cardState.cardStatus != nil && cardState.isPinVerificationSuccess
    }
    
    @State private var showSetupFlow = false
        
    var body: some View {
        NavigationStack(path: $cardState.homeNavigationPath) {
            ZStack {
                Image("bg_glow")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    HeaderView(homeNavigationPath: $cardState.homeNavigationPath)
                 
                    Spacer()
                    
                    Spacer().frame(height: 16)
                    
                    if isCardScanned {
                        DashboardView(homeNavigationPath: $cardState.homeNavigationPath)
                    } else {
                        EmptyScanStateOverlay(homeNavigationPath: $cardState.homeNavigationPath)
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
                    MenuView(homeNavigationPath: $cardState.homeNavigationPath)
                case .settings:
                    SettingsView(homeNavigationPath: $cardState.homeNavigationPath)
                case .createPinCode:
                    CreatePinCodeView(homeNavigationPath: $cardState.homeNavigationPath, pinCodeNavigationData: PinCodeNavigationData(mode: .createPinCode, pinCode: nil))
                case .confirmPinCode(let pinCodeNavigationData):
                    ConfirmPinCodeView(homeNavigationPath: $cardState.homeNavigationPath, pinCodeNavigationData: pinCodeNavigationData)
                case .setupFaceId(let pinCode):
                    SetupFaceIdView(homeNavigationPath: $cardState.homeNavigationPath, pinCode: pinCode)
                case .pinCode(let action):
                    PinCodeView(homeNavigationPath: $cardState.homeNavigationPath, actionAfterPin: action)
                case .logs:
                    LogsView(homeNavigationPath: $cardState.homeNavigationPath)
                case .cardInfo:
                    CardInfoView(homeNavigationPath: $cardState.homeNavigationPath)
                case .authenticity:
                    AuthenticityView(homeNavigationPath: $cardState.homeNavigationPath)
                case .editPinCode:
                    CreatePinCodeView(homeNavigationPath: $cardState.homeNavigationPath, pinCodeNavigationData: PinCodeNavigationData(mode: .updatePinCode, pinCode: nil))
                case .addSecret:
                    AddSecretView(homeNavigationPath: $cardState.homeNavigationPath)
                case .showSecret(let secret):
                    ShowSecretView(homeNavigationPath: $cardState.homeNavigationPath, secret: secret)
                case .generateSecretType:
                    GenerateSecretTypeView(homeNavigationPath: $cardState.homeNavigationPath)
                case .generateGenerator(let mode):
                    GenerateGeneratorView(homeNavigationPath: $cardState.homeNavigationPath, generatorMode: mode)
                case .generateSuccess(let label):
                    GenerateSuccessView(homeNavigationPath: $cardState.homeNavigationPath, secretLabel: label)
                case .backup:
                    BackupView(homeNavigationPath: $cardState.homeNavigationPath)
                }
            }
        }
        .onAppear {
            // Can be used to test logging
            // managedObjectContext.saveLogEntry(log: LogModel(type: .info, message: "Home view loaded"))
        }
    }
}
