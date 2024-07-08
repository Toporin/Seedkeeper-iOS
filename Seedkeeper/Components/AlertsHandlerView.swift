//
//  AlertsHandlerView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 08/07/2024.
//

import Foundation
import SwiftUI

struct AlertsHandlerView: View {
    @Binding var showCardNeedsToBeScannedAlert: Bool

    var body: some View {
        Group {
            if showCardNeedsToBeScannedAlert {
                cardNeedsToBeScannedAlert
            }
        }
    }

    private var cardNeedsToBeScannedAlert: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showCardNeedsToBeScannedAlert = false
                }
            SatoAlertView(
                isPresented: $showCardNeedsToBeScannedAlert,
                alert: SatoAlert(
                    title: "cardNeedToBeScannedTitle",
                    message: "cardNeedToBeScannedMessage",
                    buttonTitle: "",
                    buttonAction: {},
                    isMoreInfoBtnVisible: false
                )
            )
            .padding([.leading, .trailing], 24)
        }
    }
}

struct SatoAlert {
    var title: String
    var message: String
    var buttonTitle: String
    var buttonAction: () -> Void
    var isMoreInfoBtnVisible: Bool = true
    var imageUrl: String? = nil
}

struct SatoAlertView: View {
    @Binding var isPresented: Bool
    var alert: SatoAlert
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 16)
            SatoText(text: alert.title, style: .titleWhite)
                .font(.headline)
            Spacer()
                .frame(height: 16)
            SatoText(text: alert.message, style: .subtitle)
                .font(.body)
            Spacer()
                .frame(height: 16)
            
            VStack {
                if alert.isMoreInfoBtnVisible {
                    Button(action: {
                        alert.buttonAction()
                        isPresented = false
                    }) {
                        Text(alert.buttonTitle)
                            .padding(.horizontal, 50.0)
                            .padding()
                            .background(Colors.buttonInform)
                            .foregroundColor(.white)
                            .cornerRadius(24)
                    }
                    Spacer()
                        .frame(height: 16)
                }
                    
                Button(action: {
                    isPresented = false
                }) {
                    Text(String(localized: "close"))
                        .padding(.horizontal, 30.0)
                        .padding()
                        .background(Colors.ledBlue)
                        .foregroundColor(.white)
                        .cornerRadius(24)
                }
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
                .frame(height: 16)
        }
        .padding()
        .background(Color.fromHex("#27273C"))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

