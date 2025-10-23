import Foundation
import SwiftUI

//            New Feature:

struct FestivalView: View {
    enum sortSelection: String, CaseIterable {
        case date = "Date"
        case performers = "Performers"
        case teams = "Teams"
        case pendingApproval = "Pending"
    }
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var selected: sortSelection = .date
    @State private var showAddPerformance = false
//    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Select View", selection: $selected) {
                    ForEach(sortSelection.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                switch selected {
                case .date:
                    DateListView()
                case .performers:
                    PerformerListView()
                case .teams:
                    TeamListView()
                case .pendingApproval:
                    if authViewModel.role == .owner {
                        PendingApprovalView()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Union Comedy Festival")
            .toolbar {
                // Trailing plus button (only if admin logged in)
                if festivalViewModel.isAdminLoggedIn {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddPerformance = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddPerformance) {
                AddPerformanceView()
            }
        }
    }
}
