import Foundation

class FestivalViewModel: ObservableObject {
    @Published var performances: [Performance] = [] {
        didSet { saveData() }
    }
    @Published var knownPerformers: Set<String> = [] {
        didSet { saveData() }
    }
    // TODO: Set this to false in the final product
    @Published var isAdminLoggedIn = true
    
    let adminPassword = "Union Comedy"
    
    private let fileURL: URL = {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentDirectory.appendingPathComponent("festivalData.json")
    }()
    
    init() {
        loadData()
    }
    
    func attemptLogin(with password: String) -> Bool {
        if password == adminPassword {
            isAdminLoggedIn = true
            return true
        } else {
            return false
        }
    }
    
    func addPerformance(_ performance: Performance) {
        performances.append(performance)
        knownPerformers.formUnion(performance.performers)
    }

    func deletePerformance(_ performance: Performance) {
        if let index = performances.firstIndex(where: { $0.id == performance.id }) {
            performances.remove(at: index)
        }
    }
    
    // MARK: - Performer Management
    
    /// Deletes a performer and removes them from all teams and performances.
    func deletePerformer(named performer: String) {
        // Remove the performer from the main list of known performers
        knownPerformers.remove(performer)
        
        // Iterate through all performances and remove the performer
        for i in performances.indices {
            performances[i].performers.removeAll(where: { $0 == performer })
        }
        
        // Delete the associated image from the file system
        deleteImage(for: performer)
    }

    func saveImage(for performer: String, imageData: Data) {
        let fileName = sanitizeFilename(performer) + ".jpg"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: url)
            print("Saved image for \(performer) at \(url.path)")
        } catch {
            print("Failed to save image: \(error)")
        }
    }
    
    func hasImage(for performer: String) -> Bool {
        let fileName = sanitizeFilename(performer) + ".jpg"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func getImageURL(for performer: String) -> URL? {
        let fileName = sanitizeFilename(performer) + ".jpg"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    func deleteImage(for performer: String) {
        let fileName = sanitizeFilename(performer) + ".jpg"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: url)
            print("Deleted image for \(performer)")
        } catch {
            print("Failed to delete image: \(error)")
        }
    }
    
    private func sanitizeFilename(_ name: String) -> String {
        return name.replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "\\", with: "_")
                    .replacingOccurrences(of: ":", with: "_")
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func saveData() {
        let dataToSave = FestivalData(performances: performances, knownPerformers: Array(knownPerformers))
        do {
            let data = try JSONEncoder().encode(dataToSave)
            try data.write(to: fileURL)
            print("Data saved successfully")
        } catch {
            print("Failed to save data:", error)
        }
    }
    
    private func loadData() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(FestivalData.self, from: data)
            self.performances = decoded.performances
            self.knownPerformers = Set(decoded.knownPerformers)
            print("Data loaded successfully")
        } catch {
            print("No previous data found or failed to load:", error)
        }
    }
}

// Wrapper struct for encoding/decoding
struct FestivalData: Codable {
    var performances: [Performance]
    var knownPerformers: [String]
}
