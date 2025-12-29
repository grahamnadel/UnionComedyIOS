import SwiftUI
import PhotosUI

// Detail view showing all teams for a given performer
struct PerformerDetailView: View {
    let performer: String
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    
    @State private var loadedPerformerURL: URL?
    @State private var selectedPerformer: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
    
    
    
    @State private var testColor = false
    
    var performancesForPerformer: [Performance] {
        scheduleViewModel.performances.filter { $0.performers.contains(performer) }
            .sorted { $0.showTime < $1.showTime }
    }
    
    @State private var teamsForPerformer = [String]()
    
    var body: some View {
        ScrollView {
            VStack {
                PerformerImageView(performerURL: loadedPerformerURL ?? nil)
                    .frame(width: 250, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .navigationTitle(performer)
                    .padding()
                Text("Teams")
                    .font(.title)
                    .fontWeight(.bold)
                ForEach(teamsForPerformer, id: \.self) { team in
                        HStack {
                            Text(team)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
//                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
                .padding()
                
                BiographyView(performer: performer)
                    .padding()
                
                FavoritePerformerButton(performerName: performer)
            }
        }
        .toolbar {
            if authViewModel.role != .audience && authViewModel.approved == true && authViewModel.name == performer {
                Button(action: {
                    selectedPerformer = performer
                    isShowingPhotoPicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.purple)
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
        .onAppear {
            getTeamsForPerformer()
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
    
    private func getTeamsForPerformer() {
        print("called getTeamsForPerformer()")
        let teams = scheduleViewModel.teams
            .filter { $0.performers.contains(performer) }
            .map { $0.name }
            .sorted()
        teamsForPerformer = teams
    }
}
