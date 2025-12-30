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
        // 1️⃣ Get all performers who belong to house teams
        let houseTeamPerformers = scheduleViewModel.teams
            .filter { $0.houseTeam }        // only house teams
            .flatMap { $0.performers }      // get all performers
        let houseTeamSet = Set(houseTeamPerformers) // for fast lookup

        // 2️⃣ Start with all known performers
        let performers = Array(scheduleViewModel.knownPerformers)

        // 3️⃣ Filter: only house-team performers + search text
        let filtered = performers.filter { performer in
            houseTeamSet.contains(performer) &&
            (searchText.isEmpty || performer.localizedCaseInsensitiveContains(searchText))
        }

        // 4️⃣ Sort favorites first, then alphabetically
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
        NavigationStack {
            VStack {
                VStack {
                    SearchBar(searchCategory: "performer", searchText: $searchText)
                        .padding(.horizontal)
                }
                .background(.purple)

                List {
                    ForEach(filteredPerformers, id: \.self) { performer in
                        let performerURL = scheduleViewModel.performerImageURLs[performer]


                        NavigationLink(destination: PerformerDetailView(performer: performer)) {
                            HStack {
                                let performerURL = scheduleViewModel.performerImageURLs[performer]

                                AsyncImage(url: performerURL) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.gray)
                                        )
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Text(performer)
                                    .font(.body)
                                    .padding(.leading, 4)
                                    .foregroundColor(favoritesViewModel.favoritePerformers.contains(performer) ? favoritesViewModel.favoritePerformerColor : .primary)

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: authViewModel.role == .owner ? { indexSet in
                        if let index = indexSet.first {
                            performerToDelete = filteredPerformers[index]
                            showDeleteAlert = true
                        }
                    } : nil)
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    scheduleViewModel.loadData()
                    scheduleViewModel.loadTeams()
                    scheduleViewModel.loadPerformers()
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
  
    // 🔹 Upload a new photo
    private func loadImage(from item: PhotosPickerItem, for performer: String) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let imageData = data {
                    Task { @MainActor in
                        await scheduleViewModel.savePerformerImage(for: performer, imageData: imageData)
                        // Refresh that performer’s image
                        await scheduleViewModel.refreshPerformerImage(for: performer)

                    }
                }
            case .failure(let error):
                print("Failed to load image: \(error)")
            }
        }
    }
}
