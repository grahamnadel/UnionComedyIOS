//
//  PendingUsersView.swift
//  Union
//
//  Created by Graham Nadel on 11/4/25.
//

import Foundation
import SwiftUI

struct PendingUsersView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @State private var searchText = ""
    
    var body: some View {
        TextField("Search by name…", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
        
        Text(scheduleViewModel.pendingUsers.isEmpty ? "No pending Approvals" : "Pending Approvals")
            .font(.headline)
        
        ForEach($scheduleViewModel.pendingUsers.filter { $0.name.wrappedValue.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }, id: \.id) { $pendingUser in
            HStack {
                Spacer()
                Toggle(isOn: $pendingUser.approved) {
                    Text("Approval of \(pendingUser.name) as a \(pendingUser.role)")
                }
                .onChange(of: pendingUser.approved) { newValue in
                    Task {
                        await scheduleViewModel.updateApproval(for: pendingUser)
                    }
                }
            }
            .padding(.horizontal)
        }
        .refreshable {
            await scheduleViewModel.fetchPendingUsers()
        }
    }
}
