//
//  EditShowDateView.swift
//  Union
//
//  Created by Graham Nadel on 10/20/25.
//

import Foundation
import SwiftUI

struct EditShowDateView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    let performance: Performance
    @State private var editingPerformance: Performance?
    @State var newShowTime: Date
    @State private var selectedTeam: Team?
    var sortedTeams: [Team] {
        scheduleViewModel.teams.sorted {
            ($0.houseTeam ? 0 : 1) < ($1.houseTeam ? 0 : 1)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Show Time")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading) {
                    Picker("Team Name", selection: $selectedTeam) {
                        Text("New Team...").tag(nil as Team?)
                        
                        ForEach(sortedTeams, id: \.self) { team in
                            Text(team.name).tag(team as Team?)
                        }
                    }
                }

                DatePicker("Show Time", selection: $newShowTime, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)

                Spacer()
            }
            .padding()
            .navigationTitle("Edit Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        editingPerformance = nil
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updatePerformanceTime(performance)
                        updatePerformanceTeam(Performance(teamName: performance.teamName, showTime: newShowTime, performers: performance.performers))
                        updatePerformanceTeam(performance)
                        editingPerformance = nil
                    }
                }
            }
        }
        .onAppear {
            selectedTeam = scheduleViewModel.teams.first {
                $0.name == performance.teamName
            }
        }
    }
    
    private func updatePerformanceTime(_ performance: Performance) {
        if let index = scheduleViewModel.performances.firstIndex(where: { $0.id == performance.id }) {
            scheduleViewModel.performances[index].showTime = newShowTime
        }
    }
    
    private func updatePerformanceTeam(_ performance: Performance) {
        scheduleViewModel.swapPerformance(showTime: performance.showTime, originalTeam: performance.teamName, newTeam: selectedTeam?.name ?? "")
    }
}

