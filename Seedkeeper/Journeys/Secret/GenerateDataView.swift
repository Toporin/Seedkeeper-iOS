//
//  GenerateDataView.swift
//  Seedkeeper
//
//  Created by Satochip on 16/09/2024.
//

import Foundation
import SwiftUI
import SatochipSwift


struct GenerateDataView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    
    @Binding var homeNavigationPath: NavigationPath
    @State var generatorModeNavData: GeneratorModeNavData
    
    @State private var msgError: SecretImportWizardError? = nil
    
    @State private var labelText: String?
    @State var dataText = ""
    
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
                        
                        SatoText(text: String(localized: "importDataSecret"), style: .SKStrongBodyDark)
                        
                        Spacer()
                            .frame(height: 16)
                        
                        SatoText(text: String(localized: "importDataSecretInfoSubtitle"), style: .SKStrongBodyDark)
                        
                        Spacer()
                            .frame(height: 30)
                        
                        EditableCardInfoBox(mode: .text("Label"), backgroundColor: Colors.purpleBtn, height: 33, backgroundColorOpacity: 0.5) { labelTextResult in
                            if case .text(let customLabelText) = labelTextResult {
                                labelText = customLabelText
                            }
                        }
                        
                        Spacer()
                            .frame(height: 16)
                        
                        SKSecretViewer(secretType: .data, contentText: $dataText, isEditable: true, placeholder: "Data")

                        Spacer()
                            .frame(height: 16)
                        
                        if let msgError = msgError {
                            Text(msgError.localizedString())
                                .font(.custom("Roboto-Regular", size: 12))
                                .foregroundColor(Colors.ledRed)
                            
                            Spacer()
                                .frame(height: 16)
                        }
                        
                        // Import button for manual import
                        SKButton(text: String(localized: "import"),
                                 style: .regular, horizontalPadding: 66,
                                 isEnabled: true,
                                 action: {
                                            
                                    // check conditions
                                    guard let labelText = labelText,
                                            !labelText.isEmpty else {
                                        msgError = .emptyLabel
                                        return
                                    }
                                    guard labelText.utf8.count <= Constants.MAX_LABEL_SIZE else {
                                        msgError = .labelTooLong
                                        return
                                    }
                                    guard !dataText.isEmpty else {
                                        msgError = .emptySecret
                                        return
                                    }
                                    guard dataText.utf8.count <= Constants.MAX_FIELD_SIZE_16B else {
                                        msgError = .dataTooLong
                                        return
                                    }
                                    
                                    let payload = DataPayload(label: labelText, data: dataText)
                            
                                    if let version = cardState.masterCardStatus?.protocolVersion, version == 1 {
                                        // for v1, secret size is limited to 255 bytes
                                        let payloadBytes = payload.getPayloadBytes()
                                        if payloadBytes.count > Constants.MAX_SECRET_SIZE_FOR_V1 {
                                            msgError = .secretTooLongForV1
                                            return
                                        }
                                    }
                                    
                                    cardState.requestImportSecret(secretPayload: payload)
                        })
                        
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
                SatoText(text: "importSecret", style: .lightTitleDark)
            }
        }
    }
}

// MARK: Payload types

struct DataPayload : Payload {
    var label: String
    var data: String
    
    var type = SeedkeeperSecretType.data
    var subtype = UInt8(0x00)
    
    func getPayloadBytes() -> [UInt8] {
        let dataBytes = [UInt8](data.utf8)
        let dataSize = [UInt8((dataBytes.count>>8)%256), UInt8(dataBytes.count%256)]

        var payload: [UInt8] = []
        payload.append(contentsOf: dataSize)
        payload.append(contentsOf: dataBytes)
        
        return payload
    }
    
    func getContentString() -> String {
        return data
    }
    
    func humanReadableName() -> String {
        return "Data";
    }
}
