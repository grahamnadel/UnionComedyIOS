//
//  SelectedDatesSectionVIew.swift
//  Union
//
//  Created by Graham Nadel on 12/31/25.
//

import Foundation
import SwiftUI

struct SelectedDatesSection: View {
    @Binding var selectedDates: Set<Date>
    let redundantPerformances: [Performance]
    
    private var sortedDates: [Date] {
        selectedDates.sorted()
    }
    
    var body: some View {
        Section(header: Text("Dates to Add")) {
            ForEach(sortedDates, id: \.self) { selectedDate in
                HStack {
                    (
                        Text(selectedDate, style: .date)
                        + Text(", ")
                        + Text(selectedDate, style: .time)
                    )
                    .foregroundColor(
                        redundantPerformances.contains(where: { $0.showTime == selectedDate })
                        ? .red
                        : .green
                    )
                    
                    if redundantPerformances.contains(where: { $0.showTime == selectedDate }) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .help("Team already scheduled for this time.")
                    }
                }
            }
            .onDelete { indexSet in
                let datesToRemove = indexSet.map { sortedDates[$0] }
                selectedDates.subtract(datesToRemove)
            }
        }
    }
}
