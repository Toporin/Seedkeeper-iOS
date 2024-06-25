//
//  SeedkeeperApp.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import SwiftUI

@main
struct SeedkeeperApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var dataController = DataController.shared
    @StateObject var cardState = CardState()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(cardState)
        }
    }
}

class NavigationPathSingleton {
    static let shared = NavigationPathSingleton()
    var path: NavigationPath = NavigationPath()
}
