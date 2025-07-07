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
    @StateObject private var voteStore = VoteStore()
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    @StateObject var viewModel = ViewModel()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView(viewModel)
                .environmentObject(voteStore)
        }
        .modelContainer(sharedModelContainer)
    }
}
