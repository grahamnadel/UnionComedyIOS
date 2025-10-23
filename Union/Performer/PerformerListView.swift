import SwiftUI
import PhotosUI
import FirebaseFirestore

struct PerformerListView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedPerformer: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
    @State private var searchText = ""
    @State private var performerImageURLs: [String: URL] = [:]  // Cache URLs by performer name

    var filteredPerformers: [String] {
        let performers = festivalViewModel.knownPerformers
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

                        NavigationLink(destination: PerformerDetailView(
                            performer: performer,
                            performerURL: performerURL
                        )) {
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

                                if authViewModel.role == .owner &&
                                    performerURL == nil {
                                    Button(action: {
                                        selectedPerformer = performer
                                        isShowingPhotoPicker = true
                                    }) {
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let performerToDelete = filteredPerformers[index]
                            festivalViewModel.removePerformerFromFirebase(teamName: nil, performer: performerToDelete)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await loadPerformerImageURLs()
                }
            }
            .navigationTitle("Performers")
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
    }

    // 🔹 Load image URLs for all performers
    private func loadPerformerImageURLs() async {
        for performer in filteredPerformers {
            if performerImageURLs[performer] == nil {
                if let url = await festivalViewModel.getPerformerImageURL(for: performer) {
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
                        await festivalViewModel.savePerformerImage(for: performer, imageData: imageData)
                        // Refresh that performer’s image
                        if let url = await festivalViewModel.getPerformerImageURL(for: performer) {
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
