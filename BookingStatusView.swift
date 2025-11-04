import SwiftUI

struct BookingStatusView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @State private var selectedShowType: ShowType = .special
    @State private var selectedBookingStatus: BookingStatus = .unBooked
    
    var dates: [ShowType : [Date]] {
        scheduleViewModel.getBookingDates(for: selectedBookingStatus)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Booking Overview")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // MARK: Filters
            HStack(spacing: 12) {
                Picker("Show Type", selection: $selectedShowType) {
                    ForEach(ShowType.allCases, id: \.self) { option in
                        if option == .special {
                            Text("All Show Types").tag(option)
                        } else {
                            Text(option.displayName.capitalized).tag(option)
                        }
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Picker("Booking Status", selection: $selectedBookingStatus) {
                    ForEach(BookingStatus.allCases, id: \.self) { option in
                        Text(option.localizedDescription).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // MARK: Results
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(dates.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key.rawValue) { key, showDates in
                        if key == selectedShowType || selectedShowType == .special {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(key.displayName)
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                                    ForEach(showDates, id: \.self) { showDate in
                                        NavigationLink(destination: AddPerformanceView(date: showDate, showType: selectedShowType)) {
                                            VStack {
                                                Text(showDate, format: .dateTime.month(.abbreviated).day())
                                                    .font(.headline)
                                                Text(showDate, format: .dateTime.weekday(.abbreviated))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(colorForStatus(selectedBookingStatus))
                                            .cornerRadius(12)
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 1, y: 2)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    if dates.isEmpty {
                        Text("No shows found for this selection.")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding()
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: Helper
    private func colorForStatus(_ status: BookingStatus) -> Color {
        switch status {
        case .unBooked: return .gray.opacity(0.3)
        case .underBooked: return .yellow.opacity(0.4)
        case .booked: return .green.opacity(0.4)
        case .overBooked: return .red.opacity(0.4)
        }
    }
}
