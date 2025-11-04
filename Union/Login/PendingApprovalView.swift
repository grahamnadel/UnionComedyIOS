import SwiftUI

//TODO: Allow user to select how many months ahead to look at

enum BookingStatus: String, CaseIterable {
    case unBooked
    case underBooked
    case booked
    case overBooked
    
    var localizedDescription: String {
        switch self {
        case .unBooked:
            return "Unbooked"
        case .underBooked:
            return "Incomplete Booking"
        case .booked:
            return "Booked"
        case .overBooked:
            return "Overbooked"
        }
    }
}

struct AdminView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @State private var showPending = true
    @State private var searchText = ""
    @State private var selectedShowType: ShowType = .special
    @State private var selectedBookingStatus: BookingStatus = .unBooked
    
    var dates: [ShowType : [Date]] {
        scheduleViewModel.getBookingDates(for: selectedBookingStatus)
    }

    var body: some View {
        ScrollView {
            VStack {
                Text("Bookings")
                HStack {
                    Picker("Select View", selection: $selectedShowType) {
                        ForEach(ShowType.allCases, id: \.self) { option in
                            if option != .special {
                                Text(option.rawValue).tag(option)
                            } else if option == .special {
                                Text("All Show Types")
                            }
                        }
                    }
                    
                    Picker("Booking Status", selection: $selectedBookingStatus) {
                        ForEach(BookingStatus.allCases, id: \.self) { option in
                            Text(option.localizedDescription).tag(option)
                        }
                    }
                }
                
                ForEach(dates.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key.rawValue) { key, dates in
                    //                Make this bring up addPerformance with the current performance pulled up
                    if key == selectedShowType || selectedShowType == .special {
                        Text(key.displayName)
                        ForEach(dates, id: \.self) { showDate in
                            NavigationLink("\(showDate.formatted(.dateTime.month(.abbreviated).day()))", destination: AddPerformanceView(date: showDate, showType: selectedShowType))
                        }
                    }
                }
                
                TextField("Search by name…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                // Toggle for pending/all users
                Toggle(showPending ? "Pending Users" : "All Users", isOn: $showPending)
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 8) {
                        if showPending {
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
                        } else {
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
                        }
                    }
                }
            }
            .refreshable {
                await scheduleViewModel.fetchPendingUsers()
                await scheduleViewModel.fetchUsers()
            }
            //        .navigationTitle("Admin")
        }
    }
}
