//
//  OnBoardingWelcomeView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 21/06/2024.
//

import Foundation
import SwiftUI

struct OnboardingWelcomeView: View {
    // MARK: - Literals
    let titleText = "welcome"
    let subtitleText = "seedkeeperLetsYou"
    
    // MARK: - View
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Image("logo_seedkeeper_dark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: Dimensions.satoDimeLogoHeight)
                Spacer()
                    .frame(height: Dimensions.verticalLogoSpacing)
                SatoText(text: titleText, style: .title)
                Spacer()
                    .frame(height: Dimensions.subtitleSpacing)
                SatoText(text: subtitleText, style: .SKStrongBodyDark)
                Spacer()
                    .frame(maxHeight: 44)
                Image("il-onboard-1")
                    .frame(maxHeight: 296)
                    .scaledToFit()
                Spacer()
            }
            .padding([.leading, .trailing], Dimensions.defaultSideMargin)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.background {
            Image("bg_glow")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
    }
}

