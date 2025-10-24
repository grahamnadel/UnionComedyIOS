import SwiftUI
import PhotosUI

// Detail view showing all teams for a given performer
struct PerformerDetailView: View {
    let performer: String
    let performerURL: URL?
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    @State private var selectedPerformer: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
    @State private var performerImageURLs: [String: URL] = [:]  // Cache URLs by performer name
    @State private var biographyText = ""
    @State private var isSavingBio = false

    
    
    var performancesForPerformer: [Performance] {
        festivalViewModel.performances.filter { $0.performers.contains(performer) }
            .sorted { $0.showTime < $1.showTime }
    }
    
    // Get unique teams for this performer
    var teamsForPerformer: [String] {
        let teams = Set(performancesForPerformer.map { $0.teamName })
        return Array(teams).sorted()
    }
    
    var body: some View {
        VStack {
            PerformerImageView(performerURL: performerURL ?? nil)
            .frame(width: 250, height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .navigationTitle(performer)
            
            PerformerTeamsView(
                teamsForPerformer: teamsForPerformer,
                performancesForPerformer: performancesForPerformer,
                name: performer
            )
            .padding()
//            TODO: Add Textfield here for bios
            Button {
                festivalViewModel.toggleFavoritePerformer(performer)
            } label: {
                Image(systemName: festivalViewModel.favoritePerformers.contains(performer) ? "star.fill" : "star")
                    .foregroundColor(festivalViewModel.favoritePerformerColor)
            }
        }
        .toolbar {
            if authViewModel.role != .audience &&
                performerURL == nil && authViewModel.name == performer {
                Button(action: {
                    selectedPerformer = performer
                    isShowingPhotoPicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .task {
            await loadPerformerImageURLs()
        }
        .photosPicker(
            isPresented: $isShowingPhotoPicker,
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhoto) { photo in
            guard let photo else { return }

            photo.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let imageData = data {
                        Task { @MainActor in
                            await festivalViewModel.savePerformerImage(for: performer, imageData: imageData)
                        }
                    } else {
                        // Fallback: load the image as a file representation
                        Task {
                            do {
                                if let url = try await photo.loadTransferable(type: URL.self),
                                   let imageData = try? Data(contentsOf: url) {
                                    await MainActor.run {
                                        Task {
                                            await festivalViewModel.savePerformerImage(for: performer, imageData: imageData)
                                        }
                                    }
                                }
                            } catch {
                                print("Failed to load image via URL fallback: \(error)")
                            }
                        }
                    }

                case .failure(let error):
                    print("Failed to load image for saving: \(error)")
                }
            }
        }
    }
    
    private func loadPerformerImageURLs() async {
            if performerImageURLs[performer] == nil {
                if let url = await festivalViewModel.getPerformerImageURL(for: performer) {
                    performerImageURLs[performer] = url
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
