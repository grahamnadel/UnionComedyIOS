//
//  TeamListPerformanceRow.swift
//  Union
//
//  Created by Graham Nadel on 11/6/25.
//

import Foundation
import SwiftUI

struct TeamListPerformanceRow: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    let performance: Performance
    @State private var performerURLs: [String: URL] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let showType = ShowType.dateToShow(date: performance.showTime)?.displayName {
                Text(showType)
            }
            Text(performance.showTime, style: .date)
                .font(.subheadline)
        }
    }
}
