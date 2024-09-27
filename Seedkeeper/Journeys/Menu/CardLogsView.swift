//
//  CardLogsView.swift
//  Seedkeeper
//
//  Created by Satochip on 26/09/2024.
//

import Foundation
import SwiftUI

struct CardLogsView: View {
    // MARK: - Properties
    @EnvironmentObject var cardState: CardState
    @Binding var homeNavigationPath: NavigationPath

    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                VStack {
                    Spacer()
                        .frame(height: 16)
                    
                    HStack {
                        //Text("\(String(localized: "logsNumberOfEntries")) : \(cardState.cardLogs.count)")
                        Text("\(String(localized: "logsNumberOfEntries")) : \(cardState.nbAvailableLogs)")
                            .font(.custom("OpenSans-light", size: 16))
                            .fontWeight(.thin)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                        
                        Button(action: {
                            let logEntriesString = cardState.cardLogs.map { log in
                                return log.toString()
                            }.joined(separator: "\n")
                            
                            UIPasteboard.general.string = logEntriesString
                        }) {
                            Image(systemName: "square.on.square")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(Color.gray)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 16)
                    
                    List {
                        ForEach(cardState.cardLogs, id: \.self) { log in
                            
                            if log.ins != 0 {
                                // ignore empty elements
                                HStack(alignment: .center) {
                                    
                                    Text("ins: \(String(format:"%02X", log.ins))")
                                        .font(.custom("OpenSans-regular", size: 16))
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(8)
                                    
                                    Text("sid1: \( (log.sid1 != 0xFFFF) ? String(log.sid1) : "-")")
                                        .font(.custom("OpenSans-regular", size: 16))
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(8)
                                    
                                    Text("sid2: \( (log.sid2 != 0xFFFF) ? String(log.sid2) : "-")")
                                        .font(.custom("OpenSans-regular", size: 16))
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(8)
                                    
                                    Text("sw: \(String(format:"%04X", log.sw))")
                                        .font(.custom("OpenSans-regular", size: 16))
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(8)
                                    
                                }
                                .padding(8)
                                .listRowBackground(Color.clear)
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }// List
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                    
                }// VStack
                .overlay {
                    RoundedRectangle(cornerRadius: 12,
                                     style: RoundedCornerStyle.continuous)
                        .stroke(Color.black, lineWidth: 3)
                }
            }//VStack
            .padding(32)
            
        }// ZStack
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            homeNavigationPath.removeLast()
        }) {
            Image("ic_back_dark")
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                SatoText(text: "cardLogsViewTitle", style: .lightTitleDark)
            }
        }
    }// body
}
