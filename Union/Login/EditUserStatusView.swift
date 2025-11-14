//
//  EditUserStatusView.swift
//  Union
//
//  Created by Graham Nadel on 11/4/25.
//

import Foundation
import SwiftUI

struct EditUserStatusView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @State private var searchText = ""
    
    var body: some View {
        TextField("Search by name…", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
        
        ForEach($scheduleViewModel.users.filter { $0.name.wrappedValue.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }, id: \.id) { $appUser in
            HStack {
                Text("\(appUser.name)")
                Spacer()
                Picker("Role", selection: $appUser.role) {
                    Text("Audience").tag(UserRole.audience)
                    Text("Performer").tag(UserRole.performer)
                    Text("Coach").tag(UserRole.coach)
                    Text("Owner").tag(UserRole.owner)
                }
                .pickerStyle(.menu)
                .onChange(of: appUser.role) { newValue in
                    Task {
                        await scheduleViewModel.updateRole(for: appUser)
                    }
                }
            }
            .padding(.horizontal)
        }
        .refreshable {
            await scheduleViewModel.fetchUsers()
        }
    }
}
