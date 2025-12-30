//
//  UnionApp.swift
//  Union
//
//  Created by Graham Nadel on 6/18/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import Firebase
import FirebaseAppCheck
import FirebaseMessaging

@main
struct UnionApp: App {
    //    @StateObject private var voteStore = VoteStore()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // App Check debug provider for simulator / development
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
#if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
#endif
        configureTabBarAppearance()
    }
    //    @StateObject var viewModel = ViewModel()
    @StateObject var scheduleViewModel = ScheduleViewModel()
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var ownerViewModel = OwnerViewModel()
    @StateObject var notifications = PushNotificationManager()
    
    @StateObject var favoritesViewModel = FavoritesViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(scheduleViewModel)
                .environmentObject(ownerViewModel)
                .environmentObject(favoritesViewModel)
                .environmentObject(notifications)
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        let swiftUIPurple = UIColor(
            red: 175.0 / 255.0,
            green: 82.0 / 255.0,
            blue: 222.0 / 255.0,
            alpha: 1.0
        )
        
        appearance.configureWithOpaqueBackground()

        appearance.backgroundColor = .black

        // Optional: selected / unselected icon + text colors
        appearance.stackedLayoutAppearance.selected.iconColor = swiftUIPurple
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = .lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.lightGray
        ]

        UITabBar.appearance().standardAppearance = appearance

        // iOS 15+
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

}
