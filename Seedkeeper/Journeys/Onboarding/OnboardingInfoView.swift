//
//  OnboardingInfoView.swift
//  Satodime
//
//  Created by Lionel Delvaux on 25/09/2023.
//

import Foundation
import SwiftUI

struct OnboardingInfoView: View {
    // MARK: - Literals
    let titleText = "yourSeedPhraseManager"
    let subtitleText = "yourSeedPhraseManagerSubtitle"
    
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
                    .frame(height: 55)
                Image("il-onboard-2")
                    .frame(maxWidth: 225, maxHeight: 296)
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
