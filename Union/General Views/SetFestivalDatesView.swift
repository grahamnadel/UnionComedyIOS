import SwiftUI

struct SetFestivalDatesView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
    @State private var festivalLocation: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Festival Dates")) {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                
                DatePicker(
                    "End Date",
                    selection: Binding(
                        get: { endDate },
                        set: { newValue in
                            endDate = Calendar.current.date(
                                bySettingHour: 23,
                                minute: 59,
                                second: 0,
                                of: newValue
                            ) ?? newValue
                        }
                    ),
                    in: startDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
            }

            Section {
                HStack {
                    Text("Selected Range:")
                    Spacer()
                    Text("\(formattedDate(startDate)) → \(formattedDate(endDate))")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                TextField("Festival Location", text: $festivalLocation)
            }

            Button(action: saveDates) {
                Text("Save Dates")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.vertical)
        }
        .navigationTitle("Set Festival Dates")
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func saveDates() {
        print("Festival Dates: \(startDate) to \(endDate)")
        scheduleViewModel.saveFestivalDatesAndLocation(start: startDate, end: endDate, location: festivalLocation)
    }
}
