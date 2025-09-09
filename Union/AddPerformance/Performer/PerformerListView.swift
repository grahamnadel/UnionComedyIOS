import SwiftUI
import PhotosUI

struct PerformerListView: View {
    @ObservedObject var festivalViewModel: FestivalViewModel
    @State private var selectedPerformer: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
    
    var sortedPerformers: [String] {
        festivalViewModel.knownPerformers.sorted()
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedPerformers, id: \.self) { performer in
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
                        
                        NavigationLink(destination: PerformerDetailView(performer: performer, performerURL: performerURL ?? nil, festivalViewModel: festivalViewModel)) {
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
                        let performerToDelete = sortedPerformers[index]
                        festivalViewModel.deletePerformer(named: performerToDelete)
                    }
                }
            }
            .navigationTitle("Performers")
            .photosPicker(
                isPresented: $isShowingPhotoPicker,
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedPhoto) { newValue in
                if let selectedPhoto = newValue,
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
                    DispatchQueue.main.async {
                        festivalViewModel.saveImage(for: performer, imageData: imageData)
                    }
                }
            case .failure(let error):
                print("Failed to load image: \(error)")
            }
        }
    }
}
