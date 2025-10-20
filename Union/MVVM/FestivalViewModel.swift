import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage


class FestivalViewModel: ObservableObject {
    @Published var festivalTeams = [TeamData]()
    @Published var performances: [Performance] = []
    @Published var knownPerformers: Set<String> = []
    // TODO: Set this to false in the final product
    @Published var isAdminLoggedIn = true

    // USER FAVORITES
    @Published var favoriteTeams: [String] = []
    @Published var favoritePerformers: [String] = []
    @AppStorage("favoriteTeams") private var favoriteTeamsData: Data = Data()
    @AppStorage("favoritePerformers") private var favoritePerformersData: Data = Data()
    
    let favoriteTeamColor = Color.yellow
    let favoritePerformerColor = Color.purple
    
    let adminPassword = "Union Comedy"
    
    init() {
        loadData()
        loadFavorites()
    }
    
    
    func toggleFavoriteTeam(_ team: String) {
        if favoriteTeams.contains(team) {
            favoriteTeams.removeAll { $0 == team }
        } else {
            favoriteTeams.append(team)
        }
        saveFavorites()
    }
    

    func toggleFavoritePerformer(_ name: String) {
        if favoritePerformers.contains(name) {
            favoritePerformers.removeAll { $0 == name }
        } else {
            favoritePerformers.append(name)
        }
        saveFavorites()
    }
    

    // MARK: - Local Persistence
        private func saveFavorites() {
            if let teamData = try? JSONEncoder().encode(favoriteTeams) {
                favoriteTeamsData = teamData
            }
            if let performerData = try? JSONEncoder().encode(favoritePerformers) {
                favoritePerformersData = performerData
            }
        }

        private func loadFavorites() {
            if let loadedTeams = try? JSONDecoder().decode([String].self, from: favoriteTeamsData) {
                favoriteTeams = loadedTeams
            }
            if let loadedPerformers = try? JSONDecoder().decode([String].self, from: favoritePerformersData) {
                favoritePerformers = loadedPerformers
            }
        }

    
    func attemptLogin(with password: String) -> Bool {
        if password == adminPassword {
            isAdminLoggedIn = true
            return true
        } else {
            return false
        }
    }
    
    
    func deletePerformance(_ performance: Performance) {
        let db = Firestore.firestore()
        let teamsRef = db.collection("festivalTeams")
        let teamName = performance.teamName
        let showTime = performance.showTime
        
        teamsRef.whereField("name", isEqualTo: teamName).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding team \(teamName): \(error)")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("No team found with name: \(teamName)")
                return
            }
            
            let docRef = teamsRef.document(document.documentID)
            
            // Convert Firestore Timestamps to Dates
            let timestampArray = document.data()["showTimes"] as? [Timestamp] ?? []
            var showTimes = timestampArray.map { $0.dateValue() }
            
            // Remove the selected showTime
            showTimes.removeAll { $0 == showTime }
            
            if showTimes.isEmpty {
                // Delete entire team document
                docRef.delete { error in
                    if let error = error {
                        print("Error deleting team \(teamName): \(error)")
                    } else {
                        print("Deleted team \(teamName)")
                        
                        // 🔁 Remove local data for this team
                        DispatchQueue.main.async {
                            self.performances.removeAll {
                                $0.teamName == teamName
                            }
                            self.festivalTeams.removeAll {
                                $0.teamName == teamName
                            }
                        }
                    }
                }
            } else {
                // Update remaining showTimes
                let updatedTimestamps = showTimes.map { Timestamp(date: $0) }
                docRef.updateData(["showTimes": updatedTimestamps]) { error in
                    if let error = error {
                        print("Error updating showTimes for \(teamName): \(error)")
                    } else {
                        print("Updated showTimes for team \(teamName)")
                        
                        // 🔁 Remove this performance from local list
                        DispatchQueue.main.async {
                            self.performances.removeAll {
                                $0.teamName == teamName && $0.showTime == showTime
                            }
                            
                            // Also update the matching team in `festivalTeams`
                            if let index = self.festivalTeams.firstIndex(where: { $0.teamName == teamName }) {
                                self.festivalTeams[index].showTimes = showTimes
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Performer Management
    /// Adds a performer to a specific team's performances and to the known performers list.
    func addPerformer(named performerName: String, toTeam teamName: String) {
        let db = Firestore.firestore()
        
        let teamsRef = db.collection("festivalTeams")
        
        teamsRef.whereField("name", isEqualTo: teamName).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding team \(teamName): \(error)")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("No team found with name: \(teamName)")
                return
            }
            
            let docRef = teamsRef.document(document.documentID)
            var performers = document.data()["performers"] as? [String] ?? []
            
//            Check if performer is in the list
            if !performers.contains(performerName) {
                performers.append(performerName)
                
                docRef.updateData(["performers": performers]) { error in
                    if let error = error {
                        print("Error updating performers for team \(teamName): \(error)")
                    } else {
                        print("Successfully added performer \(performerName)")
                    }
                }
            } else {
                print("performer \(performerName) is already on the team \(teamName)")
            }
        }
        loadData()
    }


    func saveImage(for performer: String, imageData: Data) async {
        let fileName = sanitizeFilename(performer) + ".jpg"
        let storageRef = Storage.storage().reference().child("performerImages/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let db = Firestore.firestore()
        let teamsRef = db.collection("festivalTeams")
        
        do {
            // 1️⃣ Check if performer exists in festivalTeams
            let snapshot = try await teamsRef.getDocuments()
            var performerExists = false
            
            for document in snapshot.documents {
                if let performers = document.data()["performers"] as? [String],
                   performers.contains(performer) {
                    performerExists = true
                    break
                }
            }
            
            guard performerExists else {
                print("⚠️ Performer '\(performer)' not found in festivalTeams")
                return
            }
            
            // 2️⃣ Upload image data to Firebase Storage
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let url = try await storageRef.downloadURL()
            
            // 3️⃣ Save (or overwrite) performer document with the URL
            try await db.collection("performers").document(performer).setData([
                "url": url.absoluteString,
                "updated": Timestamp(date: Date())
            ])
            
            print("✅ Uploaded and linked image for \(performer)")
            
        } catch {
            print("❌ Error saving image for \(performer): \(error.localizedDescription)")
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
    }
    
    
    func loadData() {
        // Clear existing data before loading new data
        self.festivalTeams = []
        self.performances = []
        self.knownPerformers = []
        
        do {
            FirebaseManager.shared.loadFestivalTeams { teams in
                print("teams: \(teams)")
                self.festivalTeams = teams
                
                for team in self.festivalTeams {
                    print("team: \(team)")
                    for showInstance in team.showTimes {
                        print("showInstance: \(showInstance)")
                        let show = Performance(teamName: team.teamName, showTime: showInstance, performers: team.performers)
                        self.performances.append(show)
                        print("performances: \(self.performances)")
                    }
                }
                
                self.knownPerformers = self.loadKnownPerformers(performances: self.performances)
                print("Data loaded successfully")
            }
        } catch {
            print("No previous data found or failed to load:", error)
        }
    }
    
    
    func createPerformance(id: String, teamName: String, performerIds: [String], dates: [Date]) {
        FirebaseManager.shared.createPerformance(id: id, teamName: teamName, performerIds: performerIds, dates: dates)
        //        FIXME: This loads the teams, but creates duplicates
        loadData()
    }
    
    
    func loadKnownPerformers(performances: [Performance]) -> Set<String> {
        var knownPerformers = Set<String>()
        for team in performances {
            for performer in team.performers {
                knownPerformers.insert(performer)
            }
        }
        return knownPerformers
    }
    
    
    func removePerformerFromFirebase(teamName: String?, performer: String) {
        let db = Firestore.firestore()
        let teamsRef = db.collection("festivalTeams")
        
        let query: Query
        if let teamName = teamName {
            query = teamsRef.whereField("name", isEqualTo: teamName)
        } else {
            query = teamsRef // all teams
        }
        
        query.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching teams: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("⚠️ No teams found for query")
                return
            }
            
            for document in documents {
                var performers = document.data()["performers"] as? [String] ?? []
                let originalCount = performers.count
                
                performers.removeAll { $0 == performer }
                
                if performers.count != originalCount {
                    teamsRef.document(document.documentID).updateData(["performers": performers]) { error in
                        if let error = error {
                            print("❌ Error updating team \(document.documentID): \(error)")
                        } else {
                            print("✅ Removed '\(performer)' from team \(document.data()["name"] ?? "Unknown")")
                        }
                    }
                }
            }
        }
        //        Have UI reflect changes
        loadData()
    }
}

