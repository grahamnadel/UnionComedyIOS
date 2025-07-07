//
//  MainView.swift
//  Union
//
//  Created by Graham Nadel on 6/18/25.
//

import Foundation
import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: ViewModel
    
    init(_ viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                VoteView(viewModel: viewModel)
                    .tabItem {
                        Label("Vote", systemImage: "figure.boxing")
                    }
                    .navigationTitle("Cage Match")
                    .navigationBarTitleDisplayMode(.large)
                VStack {
                    Text("Vote Counts:")
                        .font(.headline)
                    
                    ForEach(viewModel.voteCounts.sorted(by: { $0.key < $1.key }), id: \.key) { team, count in
                        HStack {
                            Text(team)
                            Spacer()
                            Text("\(count)")
                        }
                    }
                }
                .padding()
                
                Button("Reset votes") {
                    viewModel.resetVotes()
                }
            }
        }
    }
}
