//
//  PerformanceRow.swift
//  Union
//
//  Created by Graham Nadel on 8/14/25.
//

import Foundation
import SwiftUI


struct PerformanceRow: View {
    let performance: Performance
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(performance.teamName)
                .font(.headline)
//            FIXME: Performance
            Text(performance.showTime, style: .date)
                .font(.subheadline)
            Text(performance.showTime, style: .time)
                .font(.subheadline)
            Text("Performers: \(performance.performers.joined(separator: ", "))")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}
