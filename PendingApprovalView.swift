//
//  PendingApprovalView.swift
//  Union
//
//  Created by Graham Nadel on 10/23/25.
//

import Foundation
import SwiftUI


struct PendingApprovalView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    
    var body: some View {
        VStack {
            Text(festivalViewModel.pendingUsers.isEmpty ? "No pending Approvals" : "Pending Approvals")
            ForEach($festivalViewModel.pendingUsers, id: \.id) { $pendingUser in
                HStack {
                    Spacer()
                    Toggle(isOn: $pendingUser.approved) {
                        Text("Approval of \(pendingUser.name) as a \(pendingUser.role)")
                    }
                    .onChange(of: pendingUser.approved) { newValue in
                        Task {
                            await festivalViewModel.updateApproval(for: pendingUser)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .refreshable {
            await festivalViewModel.fetchPendingUsers()
        }
    }
}
