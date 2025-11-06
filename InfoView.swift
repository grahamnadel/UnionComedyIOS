//
//  InfoView.swift
//  Union
//
//  Created by Graham Nadel on 11/5/25.
//

import Foundation
import SwiftUI

struct InfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Union Comedy")
                    .font(.title)
                    .bold()
                Text("593 Somerville Ave in Somerville, MA")
                Text("Contact: info@unioncomedy.com")
                Text("Hours: Friday–Saturday 7-10pm, Sunday 5pm-8pm")
                Spacer()
                Text("Festival Location: 255 Elm St, Somerville, MA 02144")
            }
            .padding()
        }
        .navigationTitle("About the Theatre")
    }
}
