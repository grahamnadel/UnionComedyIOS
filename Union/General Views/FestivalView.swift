import Foundation
import SwiftUI

struct FestivalView: View {
    enum sortSelection: String, CaseIterable {
        case date = "Date"
        case performers = "Performers"
        case teams = "Teams"
    }
    
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var selected: sortSelection = .date
    @State private var showAddPerformance = false
    @State private var showSettings = false
    
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
                }
                
                Spacer()
            }
            .navigationTitle("Union Comedy Festival")
            .toolbar {
                // Leading gear button (always visible)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
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
            .sheet(isPresented: $showSettings) {
                LoginView()
            }
            .onChange(of: festivalViewModel.isAdminLoggedIn) {
                if festivalViewModel.isAdminLoggedIn {
                    showSettings = false
                }
            }

        }
    }
}
