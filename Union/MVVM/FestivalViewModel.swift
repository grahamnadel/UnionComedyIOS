import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage


class FestivalViewModel: ObservableObject {
    @Published var festivalTeams = [TeamData]()
    @Published var performances: [Performance] = []
    @Published var knownPerformers: Set<String> = []
    @Published var isOwnerAdmin = false
    
    @Published var pendingUsers: [AppUser] = []
    
    // USER FAVORITES
    @Published var favoriteTeams: [String] = []
    @Published var favoritePerformers: [String] = []
    @AppStorage("favoriteTeams") private var favoriteTeamsData: Data = Data()
    @AppStorage("favoritePerformers") private var favoritePerformersData: Data = Data()
    
    let favoriteTeamColor = Color.yellow
    let favoritePerformerColor = Color.purple
    
    
    init() {
        loadData()
        loadFavorites()
    }
    
    func fetchBiography(for performerName: String) async -> String? {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("performers")
                .whereField("name", isEqualTo: performerName)
                .getDocuments()
            
            guard let document = snapshot.documents.first else {
                print("No bio found for \(performerName)")
                return nil
            }
            var bio = document.data()["bio"] as? String ?? ""
            return bio
            
        } catch {
            print("Error loading bio: \(error)")
            return nil
        }
    }
    
    func saveBiography(for performerName: String, bio: String) async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("performers")
                .whereField("name", isEqualTo: performerName)
                .getDocuments()
            
            guard let document = snapshot.documents.first else {
                print("No matching user found for \(performerName)")
                return
            }
            
            try await document.reference.updateData([
                "bio": bio
            ])
            
            print("Successfully updated bio for \(performerName)")
        } catch {
            print("Error updating bio: \(error)")
        }
    }
    
    func updateApproval(for user: AppUser) async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .whereField("email", isEqualTo: user.email)
                .getDocuments()
                
            guard let document = snapshot.documents.first else {
                print("No matching user found for \(user.email)")
                return
            }
            
            // 1. Update the 'approved' status in the 'users' collection
            try await document.reference.updateData([
                "approved": user.approved
            ])
            
            // 2. CHECK AND ADD TO PERFORMERS COLLECTION IF APPROVED
            if user.approved && (user.role == .performer || user.role == .coach) {
                // This function checks if the performer exists and creates them if they don't.
                // By placing it here, it only runs when the approval status is being set to true.
                FirebaseManager.shared.checkForExistingPerformers(for: [user.name])
                print("Action: Performer \(user.name) added to performers collection upon approval.")
            } else if !user.approved {
                // Optional: You could add logic here to remove them from the 'performers'
                // collection if you ever un-approved a user.
            }
            
            print("Successfully updated approval for \(user.email) to \(user.approved)")
        } catch {
            print("Error updating approval: \(error)")
        }
    }
    
    
    func fetchPendingUsers() async {
        print("fetchPendingUsers")
        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .whereField("approved", isEqualTo: false)
                .getDocuments()
            
            let users = snapshot.documents.compactMap { doc -> AppUser? in
                try? doc.data(as: AppUser.self)
            }
            DispatchQueue.main.async {
                self.pendingUsers = users
            }
        } catch {
            print("Error fetching pending users: \(error)")
        }
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
    
    
    // Upload a performer's image to Firebase Storage and save URL in Firestore
    func savePerformerImage(for performer: String, imageData: Data) async {
        let fileName = sanitizeFilename(performer) + ".jpg"
        let storageRef = Storage.storage().reference().child("performerImages/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let db = Firestore.firestore()

        do {
            // Upload image data to Firebase Storage
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            
            // Get the image's download URL
            let url = try await storageRef.downloadURL()
            
            // Find the performer document by name
            let snapshot = try await db.collection("performers")
                .whereField("name", isEqualTo: performer)
                .getDocuments()
            
            guard let document = snapshot.documents.first else {
                print("⚠️ No performer found with name \(performer).")
                return
            }
            
            // Update the existing performer document with the new URL
            let performerRef = db.collection("performers").document(document.documentID)
            try await performerRef.updateData([
                "url": url.absoluteString,
            ])
            
            print("✅ Performer image successfully saved and linked for \(performer).")
            
        } catch {
            print("❌ Error saving image for \(performer): \(error.localizedDescription)")
        }
    }

    
    // Check if a performer has an image in Firestore
    func hasPerformerImage(for performer: String) async -> Bool {
        let db = Firestore.firestore()
        do {
            let doc = try await db.collection("performers").document(performer).getDocument()
            return doc.exists && doc.data()?["url"] != nil
        } catch {
            print("Error checking image for \(performer): \(error)")
            return false
        }
    }
    
    // Get the download URL for a performer's image
    func getPerformerImageURL(for performer: String) async -> URL? {
        let db = Firestore.firestore()
        guard !performer.isEmpty else { return nil }

        do {
            let querySnapshot = try await db.collection("performers")
                .whereField("name", isEqualTo: performer)
                .getDocuments()

            guard let doc = querySnapshot.documents.first else {
                print("No performer document found for: \(performer)")
                return nil
            }

            if let urlString = doc.data()["url"] as? String {
                print("Returning URL for \(performer): \(urlString)")
                return URL(string: urlString)
            } else {
                print("No URL field found for performer: \(performer)")
            }
        } catch {
            print("Error getting image URL for \(performer): \(error)")
        }
        return nil
    }

    
    // Delete a performer's image from Firebase Storage and Firestore
    func deletePerformerImage(for performer: String) async {
        let fileName = sanitizeFilename(performer) + ".jpg"
        let storageRef = Storage.storage().reference().child("performerImages/\(fileName)")
        let db = Firestore.firestore()
        
        do {
            // Delete from Storage
            try await storageRef.delete()
            
            // Remove URL from Firestore
            try await db.collection("performers").document(performer).updateData([
                "url": FieldValue.delete()
            ])
            
            print("✅ Deleted image for \(performer)")
        } catch {
            print("❌ Error deleting image for \(performer): \(error)")
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
                
                self.loadKnownPerformers { performers in
                    self.knownPerformers = performers
                    print("known performers: \(self.knownPerformers)")
                }
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
    
    
    func loadKnownPerformers(completion: @escaping (Set<String>) -> Void) {
        let db = Firestore.firestore()
        var performerNames = Set<String>()

        db.collection("performers").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error loading known performers: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                print("⚠️ No performer documents found")
                completion([])
                return
            }

            for doc in documents {
                if let performerName = doc.data()["name"] as? String {
                    performerNames.insert(performerName)
                }
            }

            completion(performerNames)
        }
    }

    
    func removePerformerFromFirebase(teamName: String?, performerName: String) {
        let db = Firestore.firestore()
        let teamsRef = db.collection("festivalTeams")
        let performersRef = db.collection("performers")
//        Clear from performers
        let performersQuery = performersRef.whereField("name", isEqualTo: performerName)
        performersQuery.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching performers: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("Performer: \(performerName) not found in query")
                return
            }
            
            // Loop through and delete each matching document (should usually be 1)
            for document in documents {
                let docID = document.documentID
                performersRef.document(docID).delete { error in
                    if let error = error {
                        print("Error deleting performer \(performerName): \(error.localizedDescription)")
                    } else {
                        print("✅ Successfully deleted performer \(performerName) (ID: \(docID))")
                    }
                }
            }
        }
        
//        Clear from teams
        let teamsQuery: Query
        if let teamName = teamName {
            teamsQuery = teamsRef.whereField("name", isEqualTo: teamName)
        } else {
            teamsQuery = teamsRef // all teams
        }
        
        teamsQuery.getDocuments { snapshot, error in
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
                
                performers.removeAll { $0 == performerName }
                
                if performers.count != originalCount {
                    teamsRef.document(document.documentID).updateData(["performers": performers]) { error in
                        if let error = error {
                            print("❌ Error updating team \(document.documentID): \(error)")
                        } else {
                            print("✅ Removed '\(performerName)' from team \(document.data()["name"] ?? "Unknown")")
                        }
                    }
                }
            }
        }
        //        Have UI reflect changes
        loadData()
    }
}

