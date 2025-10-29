import SwiftUI
import PhotosUI

// Detail view showing all teams for a given performer
struct PerformerDetailView: View {
    let performer: String
//    let performerURL: URL?
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @State private var loadedPerformerURL: URL?
    @State private var selectedPerformer: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
//    @State private var performerImageURLs: [String: URL] = [:]  // Cache URLs by performer name  
    
    var performancesForPerformer: [Performance] {
        scheduleViewModel.performances.filter { $0.performers.contains(performer) }
            .sorted { $0.showTime < $1.showTime }
    }
    
    // Get unique teams for this performer
//    var teamsForPerformer: [String] {
//        let teams = Set(performancesForPerformer.map { $0.teamName })
//        return Array(teams).sorted()
//    }
    var teamsForPerformer: [String] {
        scheduleViewModel.teams
            .filter { $0.performers.contains(performer) }
            .map { $0.name }
            .sorted()
    }

    
    var body: some View {
        ScrollView {
            VStack {
                PerformerImageView(performerURL: loadedPerformerURL ?? nil)
                    .frame(width: 250, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .navigationTitle(performer)
                
                PerformerTeamsView(
                    teamsForPerformer: teamsForPerformer,
                    performancesForPerformer: performancesForPerformer,
                    name: performer
                )
                .padding()
                
                BiographyView(performer: performer)
                    .padding()
                
                Button {
                    scheduleViewModel.toggleFavoritePerformer(performer)
                } label: {
                    Image(systemName: scheduleViewModel.favoritePerformers.contains(performer) ? "star.fill" : "star")
                        .foregroundColor(scheduleViewModel.favoritePerformerColor)
                }
            }
            .toolbar {
                if authViewModel.role != .audience &&
                    loadedPerformerURL == nil && authViewModel.name == performer {
                    Button(action: {
                        selectedPerformer = performer
                        isShowingPhotoPicker = true
                    }) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.blue)
                    }
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
                            await scheduleViewModel.savePerformerImage(for: performer, imageData: imageData)
                        }
                    } else {
                        // Fallback: load the image as a file representation
                        Task {
                            do {
                                if let url = try await photo.loadTransferable(type: URL.self),
                                   let imageData = try? Data(contentsOf: url) {
                                    await MainActor.run {
                                        Task {
                                            await scheduleViewModel.savePerformerImage(for: performer, imageData: imageData)
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
        print("Loading performer url")
        if loadedPerformerURL == nil {
                if let url = await scheduleViewModel.getPerformerImageURL(for: performer) {
                    loadedPerformerURL = url
                }
            }
    }

    // 🔹 Upload a new photo
//    private func loadImage(from item: PhotosPickerItem, for performer: String) {
//        print("Loading performer image")
//        item.loadTransferable(type: Data.self) { result in
//            switch result {
//            case .success(let data):
//                if let imageData = data {
//                    Task { @MainActor in
//                        await scheduleViewModel.savePerformerImage(for: performer, imageData: imageData)
//                        // Refresh that performer’s image
//                        if let url = await scheduleViewModel.getPerformerImageURL(for: performer) {
//                            performerImageURLs[performer] = url
//                        }
//                    }
//                }
//            case .failure(let error):
//                print("Failed to load image: \(error)")
//            }
//        }
//    }
}
