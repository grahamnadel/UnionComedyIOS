//
//  DateListItemView.swift
//  Union
//
//  Created by Graham Nadel on 12/30/25.
//

import Foundation
import SwiftUI

struct DateListItemView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var editingPerformance: Performance?
    @Binding var showDeleteAlert: Bool
    @Binding var performanceToDelete: Performance?
    let showTime: Date
    let performances: [Performance]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Show type and time
            if let festivalStart = scheduleViewModel.festivalStartDate,
               let festivalEndDate = scheduleViewModel.festivalEndDate,
               let festivalLocation = scheduleViewModel.festivalLocation {
                
                if showTime < festivalStart || showTime > festivalEndDate {
                    PerformancesLogisticsView(showTime: showTime)
                    HStack(spacing: 0) {
                        Spacer()
                        ForEach(performances, id: \.id) { performance in
                            ShowDate(performance: performance)
                                .frame(width: 150)
                                .contextMenu {
                                    if authViewModel.role == .owner {
                                        Button("Edit Performance") {
                                            editingPerformance = performance
                                        }
                                        
                                        Button(role: .destructive) {
                                            performanceToDelete = performance
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete Performance", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    Divider()
                        .padding(.horizontal)
                } else {
                    HStack {
                        Text("Festival Show: at \(festivalLocation)")
                            .bold()
                            .foregroundColor(.purple)
                        Spacer()
                        Text(showTime.formatted(.dateTime.hour().minute()))
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
