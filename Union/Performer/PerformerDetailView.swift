import SwiftUI
import PhotosUI

// Detail view showing all teams for a given performer
struct PerformerDetailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var favoritesViewModel: FavoritesViewModel
    @State private var loadedPerformerURL: URL?
    @State private var selectedPerformer: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
    @State private var teamsForPerformer = [String]()
    @State private var testColor = false
    let performer: String
    var performancesForPerformer: [Performance] {
        scheduleViewModel.performances.filter { $0.performers.contains(performer) }
            .sorted { $0.showTime < $1.showTime }
    }
    
    var body: some View {
        ZStack {
            // Gradient background
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
            
            ScrollView {
                VStack {
                    Text(performer.uppercased())
                        .font(.title) // Uses default system font
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .kerning(1.5)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background {
                            // This replaces all previous background/overlay logic
                            Capsule()
                                .fill(.white.opacity(0.1))
                                .background(.ultraThinMaterial) // The blur
                                .clipShape(Capsule()) // Ensures the blur doesn't leak into a rectangle
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                        }
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .padding(.vertical, 16)
                    
                    if let loadedPerformerURL = loadedPerformerURL {
                        PerformerImageView(performerURL: loadedPerformerURL, performerName: performer)
                            .frame(width: 250, height: 250)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.purple.opacity(0.6),
                                                Color.pink.opacity(0.6)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                            )
                            .shadow(color: Color.purple.opacity(0.4), radius: 20, x: 0, y: 10)
                            .navigationTitle(performer)
                        Rectangle()
                            .opacity(0.0)
                            .frame(width: 100, height: 25)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Featured On")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(teamsForPerformer, id: \.self) { team in
                                Image(team.lowercased())
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 200, alignment: .center)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                    }

                    
                    BiographyView(performer: performer)
                        .padding()
                    
    //                TODO: Add following performer feature
    //                FavoritePerformerButton(performerName: performer)
                }
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
