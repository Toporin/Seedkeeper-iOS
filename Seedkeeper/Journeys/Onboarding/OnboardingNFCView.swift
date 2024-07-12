//
//  OnboardingNFCView.swift
//  Satodime
//
//  Created by Lionel Delvaux on 25/09/2023.
//

import Foundation
import SwiftUI

struct OnboardingNFCView: View {
    // MARK: - Properties
    let titleText = "usingNFC"
    let subtitleText = "usingNFCSubtitle"
    
    // MARK: - Methods
    func goToMoreInfo() {
        if let url = URL(string: Constants.moreInfo) {
            UIApplication.shared.open(url)
        }
    }
    
    func goToTutorial() {
        if let url = URL(string: String(localized: "url.tutorial")) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - View
    var body: some View {
        ZStack(alignment: .bottom) {
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("il-onboard-3")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 412)
                }
                Spacer()
                    .frame(height: 40)
            }
            .ignoresSafeArea()
            
            VStack {
                Image("logo_seedkeeper_dark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: Dimensions.satoDimeLogoHeight)
                Spacer()
                    .frame(height: Dimensions.verticalLogoSpacing)
                Spacer()
                    .frame(height: Dimensions.verticalLogoSpacing)
                SatoText(text: titleText, style: .title)
                Spacer()
                    .frame(height: Dimensions.subtitleSpacing)
                SatoText(text: subtitleText, style: .SKStrongBodyDark)
                Spacer()
                    .frame(height: 34)
                SKButton(text: String(localized: "moreInfo"), style: .inform, horizontalPadding: Dimensions.secondButtonPadding) {
                    goToMoreInfo()
                }
                Spacer()
                    .frame(height: 12)
                SKButton(text: String(localized: "tutorialBtn"), style: .satoGreen, horizontalPadding: Dimensions.secondButtonPadding) {
                    goToTutorial()
                }
                Spacer()
            }
            .padding([.leading, .trailing], Dimensions.defaultSideMargin)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }.background {
            Color.clear
        }
    }
}
