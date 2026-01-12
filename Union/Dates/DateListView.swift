import SwiftUI

struct DateListView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var editingPerformance: Performance?
    @State private var newShowTime = Date()
    @State private var searchText = ""
    @State private var selectedPerformances: Performances?
    @State private var showType: ShowType?
    @State private var showDeleteAlert = false
    @State private var performanceToDelete: Performance?
    @State private var showFilterMenu = false
    @State private var showingFestivalImage = false
    
    // MARK: - Filter + Group
    private var groupedPerformancesByTime: [(key: Date, value: [Performance])] {
        let filtered = scheduleViewModel.performances.filter { performance in
            let matchesSearch =
            searchText.isEmpty ||
            performance.teamName.localizedCaseInsensitiveContains(searchText) ||
            performance.performers.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            
            let matchesShowType: Bool
            if let selectedType = showType {
                matchesShowType = ShowType.dateToShow(date: performance.showTime)?.displayName == selectedType.displayName
            } else {
                matchesShowType = true
            }
            
            return matchesSearch && matchesShowType
        }
        
        let grouped = Dictionary(grouping: filtered) { $0.showTime }
        return grouped.sorted { $0.key < $1.key }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Gradient background matching other views
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.13, blue: 0.20),
                    Color(red: 0.25, green: 0.15, blue: 0.35),
                    Color(red: 0.15, green: 0.13, blue: 0.20)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern search bar with filter
                HStack(spacing: 12) {
                    ModernSearchBar(searchText: $searchText, placeholder: "Search shows...")
                        .frame(maxWidth: .infinity)
                    
                    // Filter button
                    Button {
                        showFilterMenu.toggle()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                                )
                                .background(.ultraThinMaterial.opacity(0.3))
                                .cornerRadius(14)
                            
                            Image(systemName: showType == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(showType == nil ? .white.opacity(0.7) : .purple)
                        }
                        .frame(width: 48, height: 48)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Show list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(groupedPerformancesByTime, id: \.key) { showTime, performances in
                            ModernShowCard(
                                showTime: showTime,
                                performances: performances,
                                editingPerformance: $editingPerformance,
                                showDeleteAlert: $showDeleteAlert,
                                performanceToDelete: $performanceToDelete
                            )
                            .onTapGesture {
                                selectedPerformances = Performances(performances: performances)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .refreshable {
                    scheduleViewModel.loadData()
                    scheduleViewModel.loadTeams()
                    scheduleViewModel.loadPerformers()
                }
            }
        }
        .onChange(of: editingPerformance) {
            newShowTime = editingPerformance?.showTime ?? Date()
        }
        .sheet(isPresented: $showFilterMenu) {
            NavigationView {
                ZStack {
                    // Matching gradient for sheet
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.13, blue: 0.20),
                            Color(red: 0.25, green: 0.15, blue: 0.35),
                            Color(red: 0.15, green: 0.13, blue: 0.20)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Filter Shows")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Button("Done") {
                                showFilterMenu = false
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.purple)
                        }
                        .padding(20)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                // All Shows option
                                FilterOptionButton(
                                    title: "All Shows",
                                    isSelected: showType == nil
                                ) {
                                    showType = nil
                                    showFilterMenu = false
                                }
                                
                                // Show type options
                                ForEach(ShowType.allCases) { type in
                                    if type != .classShow {
                                        FilterOptionButton(
                                            title: type.displayName,
                                            isSelected: showType?.displayName == type.displayName
                                        ) {
                                            showType = type
                                            showFilterMenu = false
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .navigationBarHidden(true)
            }
            .presentationDetents([.medium])
        }
        
        // Edit + Detail + Delete alert
        .sheet(item: $editingPerformance) { performance in
            EditShowDateView(performance: performance, newShowTime: newShowTime)
        }
        .sheet(item: $selectedPerformances) { performance in
            ShowtimeDetailView(performances: performance)
        }
        .alert(isPresented: $showDeleteAlert) {
            SimpleAlert.confirmDeletion(
                title: "Delete Performance?",
                message: "This will delete the selected performance permanently.",
                confirmAction: {
                    if let performance = performanceToDelete {
                        scheduleViewModel.deletePerformance(performance)
                    }
                }
            )
        }
    }
}

// MARK: - Modern Show Card Component
struct ModernShowCard: View {
    let showTime: Date
    let performances: [Performance]
    @Binding var editingPerformance: Performance?
    @Binding var showDeleteAlert: Bool
    @Binding var performanceToDelete: Performance?
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private var showTypeLabel: String {
        if let showType = ShowType.dateToShow(date: showTime) {
            return showType.displayName
        }
        return "Show"
    }
    
    private var showTypeColor: Color {
        if let showType = ShowType.dateToShow(date: showTime) {
            switch showType {
            case .fridayNightFusion, .fridayWeekendShow:
                return .red
            case .mishmash, .saturdayWeekendShow, .pickle:
                return .orange
            case .cageMatch:
                return .blue
            default:
                return .purple
            }
        }
        return .purple
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with date and show type
            VStack(alignment: .leading, spacing: 6) {
                // Show type badge
                HStack(spacing: 8) {
                    Text(showTypeLabel.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(showTypeColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(showTypeColor.opacity(0.2))
                        )
                    
                    Spacer()
                }
                
                // Date and time
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(showTime, style: .date)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(showTime, style: .time)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        showTypeColor.opacity(0.15),
                        showTypeColor.opacity(0.05)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
            
            // Performances list
            VStack(spacing: 0) {
                ForEach(Array(performances.enumerated()), id: \.element.id) { index, performance in
                    HStack(spacing: 12) {
                        // Team indicator circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.6),
                                        Color.pink.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 8, height: 8)
                        
                        // Team name
                        Text(performance.teamName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Chevron
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.02))
                    .contentShape(Rectangle())
                    .contextMenu {
                        if authViewModel.role == .owner {
                            Button {
                                editingPerformance = performance
                            } label: {
                                Label("Edit Time", systemImage: "clock")
                            }
                            
                            Button(role: .destructive) {
                                performanceToDelete = performance
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    if index < performances.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 1)
                            .padding(.leading, 40)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .background(.ultraThinMaterial.opacity(0.3))
                .cornerRadius(20)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Filter Option Button
struct FilterOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.purple.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.purple.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1.5)
                    )
                    .background(.ultraThinMaterial.opacity(0.3))
                    .cornerRadius(16)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
