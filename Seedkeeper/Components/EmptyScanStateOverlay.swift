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
    @EnvironmentObject var cardState: CardState
    
    @Binding var homeNavigationPath: NavigationPath

    var body: some View {
            VStack {
                
                Spacer()
                
                ScanButton {
                    Task {
                        // get pin first then scan card later
                        homeNavigationPath.append(NavigationRoutes.pinCode(.rescanCard))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    if let weblinkUrl = URL(string: "https://satochip.io/product/seedkeeper/") {
                        UIApplication.shared.open(weblinkUrl)
                    }
                }) {
                    HStack {
                        Text(String(localized: "noSeedKeeperYet"))
                            .multilineTextAlignment(.leading)
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

