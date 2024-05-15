//
//  EmptyScanStateOverlay.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import Foundation
import SwiftUI

struct EmptyScanStateOverlay: View {
    // MARK: - Properties
    @Binding var homeNavigationPath: NavigationPath
    @Binding var isCardScanned: Bool

    var body: some View {
            VStack {
                
                Spacer()
                
                ScanButton {
                    isCardScanned = true
                    // homeNavigationPath.append(NavigationRoutes.createPinCode(PinCodeNavigationData(mode: .createPinCode, pinCode: nil)))
                }
                
                Spacer()
                
                Button(action: {
                    if let weblinkUrl = URL(string: "https://satochip.io/product/satodime/") {
                        UIApplication.shared.open(weblinkUrl)
                    }
                }) {
                    HStack {
                        Text(String(localized: "noSeedKeeperYet"))
                        Image(systemName: "cart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    }
                }
                .padding()
                .foregroundColor(.white)
                .background(LinearGradient(gradient: Gradient(colors: [Colors.darkPurple, Colors.lightPurple]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(20)
            }
    }
}

