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
            ForEach($festivalViewModel.pendingUsers, id: \.id) { $pendingUser in
                HStack {
                    Text(pendingUser.email)
                    Spacer()
                    Toggle(isOn: $pendingUser.approved) {
                        Text("Approved")
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
    }
}
