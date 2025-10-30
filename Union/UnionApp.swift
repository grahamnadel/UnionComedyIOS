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

@main
struct UnionApp: App {
    //    @StateObject private var voteStore = VoteStore()
    
    init() {
        // App Check debug provider for simulator / development
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
#if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
#endif
        
    }
    //    @StateObject var viewModel = ViewModel()
    @StateObject var scheduleViewModel = ScheduleViewModel()
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var ownerViewModel = OwnerViewModel()
    
    var body: some Scene {
        WindowGroup {
            //            MainView()
            //                .environmentObject(voteStore)
            ////                .environmentObject(viewModel)
            //                .environmentObject(scheduleViewModel)
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(scheduleViewModel)
                .environmentObject(ownerViewModel)
            //            FestivalView()
            //                .environmentObject(scheduleViewModel)
        }
    }
}
