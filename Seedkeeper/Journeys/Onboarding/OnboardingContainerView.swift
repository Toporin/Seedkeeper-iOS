//
//  OnboardingContainerView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 21/06/2024.
//

import Foundation
import SwiftUI

enum OnboardingViewType {
    case welcome
    case info
    case nfc
}

struct OnboardingContainerView: View {
    @EnvironmentObject var cardState: CardState
    
    @State var currentPageIndex = 0 {
        didSet {
            self.isLastPageHandler()
        }
    }
    @State var isLastPage = false
    
    // MARK: - Literals
    let onboardingPages: [OnboardingViewType] = [.welcome, .info, .nfc]
    var numberOfPages: Int { onboardingPages.count }
    let startButtonTitle = String(localized: "onBoardingStartBtn")

    func goToNextPage() {
        if currentPageIndex < numberOfPages - 1 {
            currentPageIndex = currentPageIndex + 1
        }
        self.isLastPageHandler()
    }
    
    private func isLastPageHandler() {
        if currentPageIndex == numberOfPages - 1 {
            isLastPage = true
        } else {
            isLastPage = false
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(false, forKey: Constants.Keys.firstTimeUse)
        print("firstTimeUse : \(UserDefaults.standard.bool(forKey: Constants.Keys.firstTimeUse))")
        cardState.homeNavigationPath = .init()
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                TabView(selection: $currentPageIndex) {
                    ForEach(Array(onboardingPages.enumerated()), id: \.offset) { index, page in
                        switch page {
                        case .welcome:
                            OnboardingWelcomeView()
                                .tag(index)
                        case .info:
                            OnboardingInfoView()
                                .tag(index)
                        case .nfc:
                            OnboardingNFCView()
                                .tag(index)
                        }
                    }
                }
                .onChange(of: currentPageIndex) { newValue in
                    currentPageIndex = newValue
                }
                .background {
                    Image("bg_glow")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
                .onAppear {
                    // TODO: Handling the onboarding completion
                }
            }
            
            if isLastPage {
                SKButton(text: startButtonTitle, style: .inform, horizontalPadding: Dimensions.firstButtonPadding) {
                    self.completeOnboarding()
                }
                .padding(.bottom, Dimensions.defaultBottomMargin)
            } else {
                Button(action: {
                    goToNextPage()
                }) {
                    Image("bg_btn_arrow")
                        .resizable()
                        .frame(width: 71, height: 71)
                        .background(Color.clear)
                }
                .padding(.bottom, Dimensions.defaultBottomMargin)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
