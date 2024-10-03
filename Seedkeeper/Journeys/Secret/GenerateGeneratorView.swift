//
//  GenerateMnemonicView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 07/05/2024.
//

import Foundation
import SwiftUI
import SatochipSwift
import MnemonicSwift


struct GenerateGeneratorView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    
    @Binding var homeNavigationPath: NavigationPath
    @State var generatorModeNavData: GeneratorModeNavData
    
    var body: some View {
        
        switch generatorModeNavData.generatorMode {
        case .mnemonic:
            GenerateMnemonicView(homeNavigationPath: $homeNavigationPath, generatorModeNavData: generatorModeNavData)
        case .password:
            GeneratePasswordView(homeNavigationPath: $homeNavigationPath, generatorModeNavData: generatorModeNavData)
        case .descriptor:
            GenerateDescriptorView(homeNavigationPath: $homeNavigationPath, generatorModeNavData: generatorModeNavData)
        case .data:
            GenerateDataView(homeNavigationPath: $homeNavigationPath, generatorModeNavData: generatorModeNavData)
        }

    }
}

enum GenerateBtnMode {
    case willGenerate
    case willImport
}

struct GeneratorModeNavData: Hashable {
    let generatorMode: GeneratorMode
    let secretCreationMode: SecretCreationMode
    
    init(generatorMode: GeneratorMode, secretCreationMode: SecretCreationMode) {
        self.generatorMode = generatorMode
        self.secretCreationMode = secretCreationMode
    }
}

enum GeneratorMode: String, CaseIterable, Hashable, HumanReadable {
    case mnemonic
    case password
    case descriptor
    case data
    
    // TODO:  not used?
    func humanReadableName() -> String {
        switch self {
        case .mnemonic:
            return String(localized: "mnemonicPhrase")
        case .password:
            return String(localized: "loginPasswordPhrase")
        case .descriptor:
            return "descriptor"
        case .data:
            return "data"
        }
    }
}

