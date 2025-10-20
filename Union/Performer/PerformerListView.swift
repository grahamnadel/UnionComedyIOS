import SwiftUI
import PhotosUI

struct PerformerListView: View {
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var selectedPerformer: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
    @State private var searchText = ""   // <-- NEW: search text

    // Filtered & sorted performers
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
                // 🔍 Add the Search Bar
                SearchBar(searchCategory: "performer", searchText: $searchText)
                    .padding(.horizontal)

                List {
                    ForEach(filteredPerformers, id: \.self) { performer in
                        let performerURL = festivalViewModel.getImageURL(for: performer)
                        HStack {
                            // Profile image
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
                            
                            NavigationLink(destination: PerformerDetailView(
                                performer: performer,
                                performerURL: performerURL ?? nil
                            )) {
                                Text(performer)
                                    .font(.body)
                            }
                            
                            Spacer()
                            
                            // Add photo button for admins
                            if festivalViewModel.isAdminLoggedIn && !festivalViewModel.hasImage(for: performer) {
                                Button(action: {
                                    selectedPerformer = performer
                                    isShowingPhotoPicker = true
                                }) {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let performerToDelete = filteredPerformers[index]
                            // TODO: delete from Firebase
                            festivalViewModel.removePerformerFromFirebase(teamName: nil, performer: performerToDelete)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    festivalViewModel.loadData()
                }
            }
            .navigationTitle("Performers")
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

    private func loadImage(from item: PhotosPickerItem, for performer: String) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let imageData = data {
                    Task { @MainActor in
                        await festivalViewModel.saveImage(for: performer, imageData: imageData)
                    }
                }
            case .failure(let error):
                print("Failed to load image: \(error)")
            }
        }
    }
}
