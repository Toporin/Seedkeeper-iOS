//
//  GenerateDescriptorView.swift
//  Seedkeeper
//
//  Created by Satochip on 16/09/2024.
//

import Foundation
import SwiftUI
import SatochipSwift

struct GenerateDescriptorView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    
    @Binding var homeNavigationPath: NavigationPath
    @State var generatorModeNavData: GeneratorModeNavData
    
    @State private var labelText: String?
    
    @State var descriptorText = ""
    @State private var descriptorPayload: DescriptorPayload?
    
    var canImportSecret: Bool {
        if let labelText = labelText {
            return !labelText.isEmpty && descriptorText.count >= 1
        } else {
            return false
        }
    }

    func getViewTitle() -> String {
        switch generatorModeNavData.secretCreationMode {
        case .generate:
            return "" // should not happen
        case .manualImport:
            return String(localized: "importDescriptorSecret")
        }
    }
    
    func getViewSubtitle() -> String {
        switch generatorModeNavData.secretCreationMode {
        case .generate:
            return "" // should not happen
        case .manualImport:
            return String(localized: "importDescriptorSecretInfoSubtitle")
        }
    }
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            ScrollViewReader { scrollValue in
                
                ScrollView {
                    
                    VStack {
                        
                        Spacer()
                            .frame(height: 60)
                        
                        SatoText(text: self.getViewTitle(), style: .SKStrongBodyDark)
                        
                        Spacer()
                            .frame(height: 16)
                        
                        SatoText(text: self.getViewSubtitle(), style: .SKStrongBodyDark)
                        
                        Spacer()
                            .frame(height: 30)
                        
                        EditableCardInfoBox(mode: .text("Label"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { labelTextResult in
                            if case .text(let customLabelText) = labelTextResult {
                                labelText = customLabelText
                            }
                        }
                        
                        Spacer()
                            .frame(height: 16)
                        
                        SKSecretViewer(secretType: .unknown, shouldShowQRCode: .constant(false), contentText: $descriptorText, isEditable: generatorModeNavData.secretCreationMode == .manualImport) { result in
                        }

                        Spacer()
                            .frame(height: 16)
                        
                        if generatorModeNavData.secretCreationMode == .manualImport {
                            // Import button for manual import
                            SKButton(text: String(localized: "import"), style: .regular, horizontalPadding: 66, isEnabled: canImportSecret, action: {
                                                                                                    
                                var payload = DescriptorPayload(label: labelText!, descriptor: descriptorText)
                                cardState.requestImportSecret(secretPayload: payload, onSuccess: {}, onFail: {})
                                
                            })
                        }
                        
                        Spacer().frame(height: 16)
                        
                    }
                    .padding([.leading, .trailing], Dimensions.lateralPadding)
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
                SatoText(text: generatorModeNavData.secretCreationMode == .manualImport ? "importSecret" : "generateSecret", style: .lightTitleDark)
            }
        }
    }
}

// MARK: Payload types

struct DescriptorPayload : Payload {
    var label: String
    var descriptor: String
    
    var type = SeedkeeperSecretType.walletDescriptor
    var subtype = UInt8(0x00)
    
    func getPayloadBytes() -> [UInt8] {
        let dataBytes = [UInt8](descriptor.utf8)
        let dataSize = [UInt8((dataBytes.count>>8)%256), UInt8(dataBytes.count%256)]

        var payload: [UInt8] = []
        payload.append(contentsOf: dataSize)
        payload.append(contentsOf: dataBytes)
        
        return payload
    }
    
    func getFingerprintBytes() -> [UInt8] {
        return SeedkeeperSecretHeader.getFingerprintBytes(secretBytes: getPayloadBytes())
    }
}
