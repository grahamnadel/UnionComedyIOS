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
    @EnvironmentObject var viewModel: ViewModel
    @State private var teamVotedFor = ""

    var body: some View {
        VStack {
            HStack{
                ForEach(viewModel.teams) { team in
                    Button(action: {
                        viewModel.voteFor(team)
                        teamVotedFor = team.name
                    }) {
//                        FIXME: Temporary color replacement
                        TeamView(teamColor: Color.blue, teamName: team.name)
                    }
                }
            }
            .padding()
            if viewModel.hasVoted {
                Text("You voted for team \(teamVotedFor)")
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
