//
//  DashboardView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 04/05/2024.
//

import Foundation
import SwiftUI
import SatochipSwift
import CryptoSwift

struct SeedkeeperSecretHeaderDto: Hashable {
    
    public static let HEADER_SIZE = 13
    
    public var sid = 0
    public var type = SeedkeeperSecretType.defaultType
    public var subtype: UInt8 = UInt8(0) // todo:
    public var origin = SeedkeeperSecretOrigin.plainImport
    public var exportRights = SeedkeeperExportRights.exportPlaintextAllowed
    public var nbExportPlaintext: UInt8 = UInt8(0)
    public var nbExportEncrypted: UInt8 = UInt8(0)
    public var useCounter: UInt8 = UInt8(0)
    public var rfu2: UInt8 = UInt8(0) // currently not used
    public var fingerprintBytes = [UInt8](repeating: 0, count: 4)
    public var label = ""
    
    public init(secretHeader: SeedkeeperSecretHeader) {
        self.sid = secretHeader.sid
        self.type = secretHeader.type
        self.subtype = secretHeader.subtype
        self.origin = secretHeader.origin
        self.exportRights = secretHeader.exportRights
        self.nbExportPlaintext = secretHeader.nbExportPlaintext
        self.nbExportEncrypted = secretHeader.nbExportEncrypted
        self.useCounter = secretHeader.useCounter
        self.rfu2 = secretHeader.rfu2
        self.fingerprintBytes = secretHeader.fingerprintBytes
        self.label = secretHeader.label
    }
    
    func toSeedkeeperSecretHeader() -> SeedkeeperSecretHeader {
        return SeedkeeperSecretHeader(sid: sid,
                                       type: type,
                                       subtype: subtype,
                                       origin: origin,
                                       exportRights: exportRights,
                                       nbExportPlaintext: nbExportPlaintext,
                                       nbExportEncrypted: nbExportEncrypted,
                                       useCounter: useCounter,
                                       rfu2: rfu2,
                                       fingerprintBytes: fingerprintBytes,
                                       label: label)
    }
}

enum SecretSearchMode {
    case all
    case mnemonic
    case password
}

enum SecretSearchFilterOptions: String, CaseIterable, Hashable, HumanReadable {
    case allTypes
    case mnemonic
    case password
    
    func humanReadableName() -> String {
        switch self {
        case .allTypes:
            return String(localized: "allTypes")
        case .mnemonic:
            return String(localized: "mnemonic")
        case .password:
            return String(localized: "password")
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    @State var searchText: String = ""
    var searchMode: SecretSearchMode = .all
    @State var filterOptions = PickerOptions(placeHolder: String(localized: "selectFilterOptions"), items: SecretSearchFilterOptions.self, selectedOption: .allTypes)
    @State private var showFilterOptions = false
    
    private func showSecretView(secret: SeedkeeperSecretHeaderDto) -> some View {
        return SKSecretButton(secret: secret) {
            homeNavigationPath.append(NavigationRoutes.showSecret(secret))
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private func matchesSearchMode(secret: SeedkeeperSecretHeaderDto) -> Bool {
        guard let selectedOption = filterOptions.selectedOption else {
            return false
        }
        switch selectedOption {
        case .allTypes:
            return true
        case .mnemonic:
            return secret.type == .bip39Mnemonic || (secret.type == .masterseed && secret.subtype == 0x01)
        case .password:
            return secret.type == .password
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 48)
            
            SatoText(text: "manageSecretsSubtitle", style: .SKStrongBodyDark)
            
            Spacer()
                .frame(height: 48)
            
            if cardState.masterSecretHeaders.count >= Constants.minSecretsCountToDisplayFilterSearch {
                HStack {
                    TextField(String(localized: "search"), text: $searchText)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(20)
                    
                    Button(action: {
                        showFilterOptions.toggle()
                    }) {
                        Image("ic_filter")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                    .frame(height: 18)
            }
            
            SatoText(text: "mySecretsList", style: .SKStrongBodyDark)
            
            Spacer()
                .frame(height: 12)
            
            List {
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
                
                ForEach(cardState.masterSecretHeaders.filter { secret in
                    (searchText.isEmpty || secret.label.lowercased().contains(searchText.lowercased())) && matchesSearchMode(secret: secret)
                }, id: \.self) { secret in
                    if searchText.isEmpty || matchesSearchMode(secret: secret) {
                        showSecretView(secret: secret)
                    }
                }
                .listRowSeparator(.hidden)
                
            }
            .refreshable {
                Task {
                    cardState.scan()
                }
            }
            .listStyle(PlainListStyle())
            .background(Color.clear)
            
            Spacer()
        }
        .padding([.leading, .trailing], Dimensions.lateralPadding)
        .sheet(isPresented: $showFilterOptions) {
            if #available(iOS 16.4, *) {
                OptionSelectorView(pickerOptions: $filterOptions)
                    .presentationDetents([.height(Dimensions.optionSelectorSheetHeight)])
                    .presentationBackground(.ultraThinMaterial)
            } else {
                OptionSelectorView(pickerOptions: $filterOptions)
                    .presentationDetents([.height(Dimensions.optionSelectorSheetHeight)])
                    .background(Image("bg-glow-small")
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 10)
                        .edgesIgnoringSafeArea(.all))
            }
        }
    }
}

struct SKSecretButton: View {
    let secret: SeedkeeperSecretHeaderDto
    let action: () -> Void
    
    func getSecretIcon(secretType: SeedkeeperSecretType) -> String {
        switch secretType {
        case .bip39Mnemonic:
            return "ic_leaf"
        case .masterseed:
            return "ic_leaf"
        case .password:
            return "ic_3DotsUnderlined"
        default:
            return "ic_key"
        }
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Spacer()
                    .frame(width: 12)
                Image(self.getSecretIcon(secretType: secret.type))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                
                Spacer()

                SatoText(text: secret.label, style: .SKStrongBodyLight)
                
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
