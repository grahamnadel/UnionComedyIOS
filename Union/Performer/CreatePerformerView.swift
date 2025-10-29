import SwiftUI

struct CreatePerformerView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    let teamName: String
    
    @State private var newPerformerName: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Performer Details") {
                    TextField("Performer Name", text: $newPerformerName)
                }
            }
            .navigationTitle("New Performer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Performer") {
                        scheduleViewModel.addPerformer(named: newPerformerName, toTeam: teamName)
                        dismiss()
                    }
                    .disabled(newPerformerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
