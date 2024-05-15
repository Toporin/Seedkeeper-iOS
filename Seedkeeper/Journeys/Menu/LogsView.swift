//
//  LogsView.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 21/05/2024.
//

import Foundation
import SwiftUI

struct LogsView: View {
    // MARK: - Properties
    @FetchRequest(sortDescriptors: []) var logEntries: FetchedResults<LogEntry>
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
                        Text("number of entries : \(logEntries.count)")
                            .font(.custom("OpenSans-light", size: 16))
                            .fontWeight(.thin)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                        
                        Button(action: {
                            let logEntriesString = logEntries.map { logEntry in
                                let log = LogModel(logEntry: logEntry)
                                return "\(Formatter().dateTimeToString(date: log.date)) - \(log.type) - \(log.message)"
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
                        ForEach(logEntries, id: \.date) { logEntry in
                            let log = LogModel(logEntry: logEntry)
                            VStack(alignment: .center) {
                                
                                Text("\(Formatter().dateTimeToString(date: log.date)) - \(log.type)")
                                    .font(.custom("OpenSans-regular", size: 16))
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(8)
                                
                                Text(log.message)
                                    .font(.custom("OpenSans-light", size: 16))
                                    .fontWeight(.thin)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(8)
                                
                            }
                            .padding(8)
                            .listRowBackground(Color.clear)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12,
                                     style: RoundedCornerStyle.continuous)
                        .stroke(Color.black, lineWidth: 3)
                }
            }
            .padding(32)
            
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
                SatoText(text: "logsViewTitle", style: .lightTitleDark)
            }
        }
    }
}
