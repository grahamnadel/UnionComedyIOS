//
//  EditShowDateView.swift
//  Union
//
//  Created by Graham Nadel on 10/20/25.
//

import Foundation
import SwiftUI

struct EditShowDateView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    let performance: Performance
    @State private var editingPerformance: Performance?
    @State var newShowTime: Date
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Show Time")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading) {
                    Text("Team: \(performance.teamName)")
                        .font(.headline)
                    Text("Performers: \(performance.performers.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                        editingPerformance = nil
                    }
                }
            }
        }
    }
    
    private func updatePerformanceTime(_ performance: Performance) {
        if let index = festivalViewModel.performances.firstIndex(where: { $0.id == performance.id }) {
            festivalViewModel.performances[index].showTime = newShowTime
        }
    }
}
