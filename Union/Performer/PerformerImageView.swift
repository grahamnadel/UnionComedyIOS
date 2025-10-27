//
//  PerformerImage.swift
//  Union
//
//  Created by Graham Nadel on 8/22/25.
//

import Foundation
import SwiftUI

struct PerformerImageView: View {
    let performerURL: URL?
    
    var body: some View {
        if let performerURL = performerURL {
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
        } else {
            Text("No Performer URL")
        }
    }
}
