//
//  TeamDetailSection.swift
//  Union
//
//  Created by Graham Nadel on 10/28/25.
//

import Foundation
import SwiftUI


struct TeamDetailSection: View {
    let allTeams: [String]
    @Binding var selectedTeamName: String?
    @Binding var teamName: String // The unified, final name
    
    @State private var newTeamNameInput: String = "" // Local state for new input
    
    var body: some View {
        Section(header: Text("Team Details")) {
            Picker("Team Name", selection: $selectedTeamName) {
                Text("New Team...").tag(nil as String?)
                
                ForEach(allTeams, id: \.self) { team in
                    Text(team).tag(team as String?)
                }
            }
            
            if selectedTeamName == nil {
                TextField("New Team Name", text: $newTeamNameInput)
                    // Update the final teamName binding directly from local state
                    .onChange(of: newTeamNameInput) {
                        teamName = newTeamNameInput
                    }
                    .onAppear {
                        // Ensure 'teamName' is initially set from local input when 'New Team' is selected
                        teamName = newTeamNameInput
                    }
            }
        }
    }
}
