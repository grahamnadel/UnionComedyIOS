//
//  ContentView.swift
//  Union
//
//  Created by Graham Nadel on 6/18/25.
//

import SwiftUI
import SwiftData


struct VoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @ObservedObject var viewModel: ViewModel

    var body: some View {
            HStack{
                ForEach(viewModel.teams) { team in
                    Button(action: {
                        viewModel.voteFor(team)
                    }) {
                        TeamView(teamColor: team.color, teamName: team.name)
                    }
                }
            }
            .padding()
    }
    

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

//#Preview {
//    VoteView()
//        .modelContainer(for: Item.self, inMemory: true)
//}
