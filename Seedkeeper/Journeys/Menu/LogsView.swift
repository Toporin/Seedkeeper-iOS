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
    @EnvironmentObject var cardState: CardState
//    @Binding var homeNavigationPath: NavigationPath

    // if using persistence
//    @FetchRequest(sortDescriptors: []) var logEntries: FetchedResults<LogEntry>

    var loggerService: PLoggerService
    var logs: [Log]
    
    init() {
        self.loggerService = LoggerService.shared
        self.logs = loggerService.getLogs()
    }
    
    // MARK: Helpers
    func formatLog(log: Log) -> String {
        return "\(self.formatLogLevel(level: log.level)) - \(log.time.formatted(date: .numeric, time: .shortened))"
    }
    
    func formatLogLevel(level: LogLevel) -> String {
        switch level{
        case .info:
            return "🔵 INFO"
        case .debug:
            return "🟢 DEBUG"
        case .warn:
            return "🟡 WARNING"
        case .error:
            return "🔴 ERROR"
        case .critical:
            return "🔴 FATAL"
        }
    }
    
    var body: some View {
        ZStack {
            Image("bg_glow")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack {
                    VStack {
                        Spacer()
                            .frame(height: 16)
                        
                        // HEADER
                        HStack {
                            //Text("\(String(localized: "logsNumberOfEntries")) : \(logEntries.count)") // using persistence
                            Text("\(String(localized: "logsNumberOfEntries")) : \(logs.count)")
                                .font(.custom("OpenSans-light", size: 16))
                                .fontWeight(.thin)
                                .multilineTextAlignment(.center)
                                .lineSpacing(8)
                            
                            Button(action: {
                                    
                                // using persistence
//                                let logEntriesString = logEntries.map { logEntry in
//                                    let log = LogModel(logEntry: logEntry)
//                                    return "\(Formatter().dateTimeToString(date: log.time)) - \(log.level) - \(log.msg)"
//                                }.joined(separator: "\n")
                                    
                                let logEntriesString = logs.map { log in
                                    return "\(Formatter().dateTimeToString(date: log.time)) - \(log.level) - \(log.msg)"
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
                        
                        // using persistence
//                        List {
//                            ForEach(logEntries, id: \.date) { logEntry in
//                                let log = LogModel(logEntry: logEntry)
//                                VStack(alignment: .center) {
//                                  // TODO
//                                }
//                                .padding(8)
//                                .listRowBackground(Color.clear)
//                                .frame(maxWidth: .infinity, alignment: .center)
//                            }
//                            .listRowSeparator(.hidden)
//                        }
//                        .listStyle(PlainListStyle())
//                        .background(Color.clear)
                        
                        ForEach(logs, id: \.self) { log in
                            VStack(alignment: .center) {
                                
                                SatoText(text: self.formatLog(log: log), style: .lightSubtitleDark)
                                if log.tag != "" {
                                    SatoText(text: "\(log.tag)", style:SatoTextStyle.lightSubtitleDark)
                                }
                                SatoText(text: "\(log.msg)", style: SatoTextStyle.lightSubtitleDark, alignment: .leading)
                                Divider()
                                
                            }
                            .padding(8)
                            .listRowBackground(Color.clear)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }// for
                        .listRowSeparator(.hidden)

                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12,
                                         style: RoundedCornerStyle.continuous)
                        .stroke(Color.black, lineWidth: 3)
                    }
                }//VStack
                .padding(32)
            }// ScrollView
            
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
//            homeNavigationPath.removeLast()
            cardState.homeNavigationPath.removeLast()
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
