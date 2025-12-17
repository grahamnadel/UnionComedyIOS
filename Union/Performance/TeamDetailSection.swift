//
//  TeamDetailSection.swift
//  Union
//
//  Created by Graham Nadel on 10/28/25.
//

import Foundation
import SwiftUI


struct TeamDetailSection: View {
    let allTeams: [Team]
    @Binding var selectedTeam: Team?
    @Binding var teamName: String
    @Binding var houseTeam: Bool
    @State private var newTeamNameInput: String = ""
    var sortedTeams: [Team] {
        allTeams.sorted {
            ($0.houseTeam ? 0 : 1) < ($1.houseTeam ? 0 : 1)
        }
    }

    var body: some View {
        Section(header: Text("Team Details")) {
            Picker("Team Name", selection: $selectedTeam) {
                Text("New Team...").tag(nil as Team?)
                
                ForEach(sortedTeams, id: \.self) { team in
                    Text(team.name).tag(team as Team?)
                }
            }
            if let selectedTeam = selectedTeam {
            } else {
                Toggle(
                    houseTeam ? "House Team": "Non House Team",
                    isOn: $houseTeam
                )
            }
            
            if selectedTeam == nil {
                TextField("New Team Name", text: $newTeamNameInput)
                    // Update the final teamName binding directly from local state
                    .onChange(of: newTeamNameInput) {
                        teamName = newTeamNameInput
                    }
                    .onAppear {
                        // Ensure 'teamName' is initially set from local input when 'New Team' is selected
                        teamName = newTeamNameInput
                        print("selectedTeam: \(String(describing: selectedTeam))/nteamName: \(teamName)")
                    }
            }
        }
    }
}
