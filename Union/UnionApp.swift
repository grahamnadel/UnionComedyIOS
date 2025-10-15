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

@main
struct UnionApp: App {
//    @StateObject private var voteStore = VoteStore()
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
//    @StateObject var viewModel = ViewModel()
    @StateObject var festivalViewModel = FestivalViewModel()

    var body: some Scene {
        WindowGroup {
//            MainView()
//                .environmentObject(voteStore)
////                .environmentObject(viewModel)
//                .environmentObject(festivalViewModel)
            FestivalView()
                .environmentObject(festivalViewModel)
        }
    }
}
