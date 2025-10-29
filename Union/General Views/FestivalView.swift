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
    var availableOptions: [sortSelection] {
        if authViewModel.role == .owner {
            return sortSelection.allCases
        } else {
            return sortSelection.allCases.filter { $0 != .pendingApproval }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Select View", selection: $selected) {
                    ForEach(availableOptions, id: \.self) { option in
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
                    PendingApprovalView()
                }
                
                Spacer()
            }
            .navigationTitle("Union Comedy Festival")
            .toolbar {
                // Trailing plus button (only if admin logged in)
                if authViewModel.role == .owner {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddPerformance = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Sign Out") {
                            authViewModel.signOut()
                        }
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            
            .sheet(isPresented: $showAddPerformance) {
                AddPerformanceView()
            }
        }
    }
}
