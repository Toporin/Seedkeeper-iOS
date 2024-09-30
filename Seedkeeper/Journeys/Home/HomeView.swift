//
//  HomeView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import SwiftUI
import SatochipSwift

enum ActionAfterPin {
    case rescanCard
    case continueBackupFlow
    case editPinCode
    case dismiss
}

enum SecretCreationMode {
    case generate
    case manualImport
}

enum NavigationRoutes: Hashable {
    case home
    case onboarding
    case menu
    case settings
    case createPinCode(PinCodeNavigationData)
    case confirmPinCode(PinCodeNavigationData)
    case logs
    case cardInfo
    case editLabel(String)
    case authenticity
    case editPinCodeRequest
    case editPinCode
    case pinCode(ActionAfterPin)
    case addSecret
    case showSecret(SeedkeeperSecretHeader)
    case generateSecretType(SecretCreationMode)
    case generateGenerator(GeneratorModeNavData)
    case generateSuccess(String)
    case backup
    case backupSuccess
    case backupFailed
    case factoryReset
    case factoryResetResult(ResetResult)
    case showCardLogs
}

struct HomeView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var cardState: CardState
    @State var showCardNeedsToBeScannedAlert: Bool = false
    
    @State private var showSetupFlow = false
    
    func isFirstTimeUse() -> Bool {
        let firstTimeUse = UserDefaults.standard.bool(forKey: Constants.Keys.firstTimeUse)
        return firstTimeUse
    }
      
    var body: some View {
        NavigationStack(path: $cardState.homeNavigationPath) {
            ZStack {
                Image("bg_glow")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    HeaderView(homeNavigationPath: $cardState.homeNavigationPath, showCardNeedsToBeScannedAlert: self.$showCardNeedsToBeScannedAlert)
                 
                    Spacer()
                    
                    Spacer().frame(height: 16)
                    
                    if cardState.isCardDataAvailable {
                        DashboardView(homeNavigationPath: $cardState.homeNavigationPath)
                    } else {
                        EmptyScanStateOverlay(homeNavigationPath: $cardState.homeNavigationPath)
                    }
                }
            }
            .overlay(
                Group {
                    // Use AlertsHandler to show one or more alerts when needed
                    AlertsHandlerView(
                        showCardNeedsToBeScannedAlert: self.$showCardNeedsToBeScannedAlert
                        )
                }
            )
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .navigationDestination(for: NavigationRoutes.self) { route in
                switch route {
                case .home:
                    HomeView()
                case .onboarding:
                    OnboardingContainerView()
                case .menu:
                    MenuView(homeNavigationPath: $cardState.homeNavigationPath)
                case .settings:
                    SettingsView(homeNavigationPath: $cardState.homeNavigationPath)
                case .createPinCode(let pinCodeNavigationData):
                    CreatePinCodeView(homeNavigationPath: $cardState.homeNavigationPath, pinCodeNavigationData: pinCodeNavigationData)
                case .confirmPinCode(let pinCodeNavigationData):
                    ConfirmPinCodeView(homeNavigationPath: $cardState.homeNavigationPath, pinCodeNavigationData: pinCodeNavigationData)
                case .pinCode(let action):
                    PinCodeView(homeNavigationPath: $cardState.homeNavigationPath, actionAfterPin: action)
                case .logs:
//                    LogsView(homeNavigationPath: $cardState.homeNavigationPath)
                    LogsView()
                case .cardInfo:
                    CardInfoView(homeNavigationPath: $cardState.homeNavigationPath)
                case .editLabel(let currentLabel):
                    EditLabelView(homeNavigationPath: $cardState.homeNavigationPath, currentLabel: currentLabel)
                case .authenticity:
                    AuthenticityView(homeNavigationPath: $cardState.homeNavigationPath)
                case .editPinCodeRequest:
                    PinCodeView(homeNavigationPath: $cardState.homeNavigationPath, actionAfterPin: .editPinCode)
                case .editPinCode:
                    CreatePinCodeView(homeNavigationPath: $cardState.homeNavigationPath, pinCodeNavigationData: PinCodeNavigationData(mode: .updatePinCodeDefineNew, pinCode: nil))
                case .addSecret:
                    AddSecretView(homeNavigationPath: $cardState.homeNavigationPath)
                case .showSecret(let secret):
                    ShowSecretView(homeNavigationPath: $cardState.homeNavigationPath, secret: secret)
                case .generateSecretType(let mode):
                    GenerateSecretTypeView(homeNavigationPath: $cardState.homeNavigationPath, secretCreationMode: mode)
                case .generateGenerator(let mode):
                    GenerateGeneratorView(homeNavigationPath: $cardState.homeNavigationPath, generatorModeNavData: mode)
                case .generateSuccess(let label):
                    GenerateSuccessView(homeNavigationPath: $cardState.homeNavigationPath, secretLabel: label)
                case .backup:
                    BackupView(homeNavigationPath: $cardState.homeNavigationPath)
                case .backupSuccess:
                    BackupCongratsView(homeNavigationPath: $cardState.homeNavigationPath)
                case .backupFailed:
                    BackupFailedView(homeNavigationPath: $cardState.homeNavigationPath)
                case .factoryReset:
                    FactoryResetView(homeNavigationPath: $cardState.homeNavigationPath)
                case .factoryResetResult(let resultCode):
                    FactoryResetResultView(homeNavigationPath: $cardState.homeNavigationPath, resultCode: resultCode)
                case .showCardLogs:
                    CardLogsView(homeNavigationPath: $cardState.homeNavigationPath)
                }
            }
        }
        .onAppear {
            if isFirstTimeUse() {
                cardState.homeNavigationPath.append(NavigationRoutes.onboarding)
            }
            // Can be used to test logging
            // managedObjectContext.saveLogEntry(log: LogModel(type: .info, message: "Home view loaded"))
        }
    }
}
