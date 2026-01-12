import SwiftUI
import PhotosUI
import FirebaseFirestore

struct PerformerListView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    
    @State private var selectedPerformer: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var performerToDelete: String?

    var filteredPerformers: [String] {
        let houseTeamPerformers = scheduleViewModel.teams
            .filter { $0.houseTeam }
            .flatMap { $0.performers }
        let houseTeamSet = Set(houseTeamPerformers)

        let performers = Array(scheduleViewModel.knownPerformers)

        let filtered = performers.filter { performer in
            houseTeamSet.contains(performer) &&
            (searchText.isEmpty || performer.localizedCaseInsensitiveContains(searchText))
        }

        return filtered.sorted { lhs, rhs in
            let lhsFavorite = favoritesViewModel.favoritePerformers.contains(lhs)
            let rhsFavorite = favoritesViewModel.favoritePerformers.contains(rhs)

            if lhsFavorite && !rhsFavorite {
                return true
            } else if !lhsFavorite && rhsFavorite {
                return false
            } else {
                return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
            }
        }
    }

    var body: some View {
        ZStack {
            // Gradient background matching FestivalView
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
                // Modern search bar
                ModernSearchBar(searchText: $searchText, placeholder: "Search performers...")
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                
                // Performer list with modern cards
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPerformers, id: \.self) { performer in
                            NavigationLink(destination: PerformerDetailView(performer: performer)) {
                                PerformerCard(
                                    performer: performer,
                                    imageURL: scheduleViewModel.performerImageURLs[performer],
                                    isFavorite: favoritesViewModel.favoritePerformers.contains(performer),
                                    favoriteColor: favoritesViewModel.favoritePerformerColor
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                if authViewModel.role == .owner {
                                    Button(role: .destructive) {
                                        performerToDelete = performer
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete Performer", systemImage: "trash")
                                    }
                                }
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
        .photosPicker(
            isPresented: $isShowingPhotoPicker,
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhoto) {
            if let selectedPhoto = selectedPhoto,
               let performer = selectedPerformer {
                loadImage(from: selectedPhoto, for: performer)
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            SimpleAlert.confirmDeletion(
                title: "Delete Performer?",
                message: "This will remove the performer from all teams and delete their profile.",
                confirmAction: {
                    if let performer = performerToDelete {
                        scheduleViewModel.removePerformerFromFirebase(teamName: nil, performerName: performer)
                        scheduleViewModel.loadPerformers()
                    }
                }
            )
        }
    }
  
    private func loadImage(from item: PhotosPickerItem, for performer: String) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let imageData = data {
                    Task { @MainActor in
                        await scheduleViewModel.savePerformerImage(for: performer, imageData: imageData)
                        await scheduleViewModel.refreshPerformerImage(for: performer)
                    }
                }
            case .failure(let error):
                print("Failed to load image: \(error)")
            }
        }
    }
}

// MARK: - Modern Performer Card Component
struct PerformerCard: View {
    let performer: String
    let imageURL: URL?
    let isFavorite: Bool
    let favoriteColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            // Profile image with gradient overlay
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.3),
                                        Color.pink.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                // Favorite indicator
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .blur(radius: 2)
                        )
                        .offset(x: 4, y: 4)
                }
            }
            
            // Performer name
            Text(performer)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isFavorite ? favoriteColor : .white)
                .lineLimit(2)
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .background(.ultraThinMaterial.opacity(0.3))
                .cornerRadius(18)
                .shadow(color: isFavorite ? favoriteColor.opacity(0.2) : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Modern Search Bar Component
struct ModernSearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
            
            TextField("", text: $searchText)
                .placeholder(when: searchText.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.4))
                }
                .foregroundColor(.white)
                .focused($isFocused)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color.purple.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1.5)
                )
                .background(.ultraThinMaterial.opacity(0.3))
                .cornerRadius(16)
        )
    }
}

// MARK: - TextField Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
