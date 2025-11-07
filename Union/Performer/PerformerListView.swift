import SwiftUI
import PhotosUI
import FirebaseFirestore

struct PerformerListView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedPerformer: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
    @State private var searchText = ""
    @State private var performerImageURLs: [String: URL] = [:]  // Cache URLs by performer name
    @State private var showDeleteAlert = false
    @State private var performerToDelete: String?


    var filteredPerformers: [String] {
        var performers = [String]()
        for team in scheduleViewModel.teams {
            team.performers.forEach { performers.append($0) }
        }
        if searchText.isEmpty {
            return performers.sorted()
        } else {
            return performers.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }.sorted()
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(searchCategory: "performer", searchText: $searchText)
                    .padding(.horizontal)

                List {
                    ForEach(filteredPerformers, id: \.self) { performer in
                        let performerURL = performerImageURLs[performer]

                        NavigationLink(destination: PerformerDetailView(performer: performer)) {
                            HStack {
                                AsyncImage(url: performerURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
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
                    await loadPerformerImageURLs()
                }
            }
//            .navigationTitle("Performers")
            .task {
                await loadPerformerImageURLs()
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
                    }
                }
            )
        }
    }
    

    // 🔹 Load image URLs for all performers
    private func loadPerformerImageURLs() async {
        for performer in filteredPerformers {
            if performerImageURLs[performer] == nil {
                print("getting performer image url")
                if let url = await scheduleViewModel.getPerformerImageURL(for: performer) {
                    performerImageURLs[performer] = url
                }
            }
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
                        if let url = await scheduleViewModel.getPerformerImageURL(for: performer) {
                            performerImageURLs[performer] = url
                        }
                    }
                }
            case .failure(let error):
                print("Failed to load image: \(error)")
            }
        }
    }
}
