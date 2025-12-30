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
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel // Needed only for the color
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel

    var body: some View {
        HStack {
            AsyncImage(url: performerURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(performer)
                .font(.body)
                .foregroundColor(favoritesViewModel.favoritePerformers.contains(performer) ? favoritesViewModel.favoritePerformerColor : .primary)
                .padding(.vertical, 4)
        }
    }
}
