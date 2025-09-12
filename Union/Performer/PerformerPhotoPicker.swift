import SwiftUI
import PhotosUI

struct PerformerPhotoPicker: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var selectedImageData: Data?

    var body: some View {
        Section(header: Text("Performer Photo")) {
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo")
                    Text("Select Performer Photo")
                }
            }

            if let data = selectedImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
