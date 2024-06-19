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

struct DashboardView: View {
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 48)
            
            SatoText(text: "manageSecretsSubtitle", style: .SKStrongBodyDark)
            
            Spacer()
                .frame(height: 48)
            
            SatoText(text: "mySecretsList", style: .SKStrongBodyDark)
            
            Spacer()
                .frame(height: 12)
            
            List {
                ForEach(cardState.masterSecretHeaders, id: \.self) { secret in
                    SKSecretButton(secret: secret.label) {
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
