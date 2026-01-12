//
//  PerformerRowContent.swift
//  Union
//
//  Created by Graham Nadel on 11/13/25.
//

import Foundation
import SwiftUI

struct PerformerRowContent: View {
    let performer: String
    let performerURL: URL?
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel

    var body: some View {
        HStack(spacing: 14) {
            // Performer image with modern styling
            AsyncImage(url: performerURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.3),
                                    Color.pink.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Performer name with white text
            Text(performer)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(
                    favoritesViewModel.favoritePerformers.contains(performer)
                    ? favoritesViewModel.favoritePerformerColor
                    : .white
                )
        }
    }
}
