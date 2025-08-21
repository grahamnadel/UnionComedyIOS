//
//  SettingsView.swift
//  Union
//
//  Created by Graham Nadel on 7/8/25.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ViewModel
    @State private var showResetConfirmation = false
    
    init(_ viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            Text("Vote Counts:")
                .font(.headline)
            
            ForEach(viewModel.voteCounts.sorted(by: { $0.key < $1.key }), id: \.key) { team, count in
                HStack {
                    Text(team)
                        .font(.title3)
                    Spacer()
                    Text("\(count)")
                        .font(.title3)
                }
            }
            .padding()
            
            ForEach($viewModel.teams) { $team in
                HStack {
                    TextField("Team Name", text: $team.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                    Spacer()
                    Text("\(viewModel.voteCounts[team.name, default: 0])")
                        .font(.title3)
                }
            }
            
            Spacer()
            
            Button("Reset vote count") {
                showResetConfirmation = true
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)
            .alert("Are you sure you want to delete the vote count?", isPresented: $showResetConfirmation) {
                Button("Reset Vote Count", role: .destructive) {
                    viewModel.resetVotes()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will set all votes to zero")
            }
        }
    }
}
