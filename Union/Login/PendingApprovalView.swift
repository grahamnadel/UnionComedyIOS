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
    
    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                
                NavigationLink(destination: BookingStatusView()) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title3)
                        Text("View Booking Status")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .buttonStyle(.plain)
                .padding()
                
                NavigationLink(destination: EditUserStatusView()) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.title3)
                        Text("Edit User Status")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .buttonStyle(.plain)
                .padding()
                
                NavigationLink(destination: PendingUsersView()) {
                    HStack {
                        Image(systemName: "person.badge.clock")
                            .font(.title3)
                        Text("Pending Users")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .buttonStyle(.plain)
                .padding()
                
                NavigationLink(destination: SetFestivalDatesView()) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.title3)
                        Text("Set Festival Dates")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .buttonStyle(.plain)
                .padding()
                
            }
            .refreshable {
                await scheduleViewModel.fetchPendingUsers()
                await scheduleViewModel.fetchUsers()
            }
        }
    }
}
