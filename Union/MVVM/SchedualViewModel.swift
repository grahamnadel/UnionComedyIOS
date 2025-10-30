import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage


class ScheduleViewModel: ObservableObject {
    @Published var festivalTeams = [TeamData]()
    @Published var performances: [Performance] = []
    @Published var teams: [Team] = []
    @Published var knownPerformers: Set<String> = []
    @Published var isOwnerAdmin = false
    
    @Published var unBooked: [ShowType: [Date]] = [:]
    @Published var underBooked: [ShowType: [Date]] = [:]
    @Published var fullyBooked: [ShowType: [Date]] = [:]
    @Published var overBooked: [ShowType: [Date]] = [:]
    
    @Published var pendingUsers: [AppUser] = []
    @Published var users: [AppUser] = []
    
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
        loadTeams()
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
    
    func updateRole(for user: AppUser) async {
        print("updating role to \(user.role)")
        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .whereField("email",isEqualTo: user.email)
                .getDocuments()
            
            guard let document = snapshot.documents.first else {
                print("no matching user found for \(user.email) when updating role")
                return
            }
            
//                        If the user will no longer be a performer, remove them from the performers
            if let originalRole = document.get("role") as? String {
                print("originalRole: \(originalRole)")
                if originalRole == UserRole.coach.rawValue || originalRole == UserRole.performer.rawValue || originalRole == UserRole.owner.rawValue  && (user.role == UserRole.audience) {
                    print("removing \(user.name) from \(user.role) due to role change")
                    removePerformerFromFirebase(teamName: nil, performerName: user.name)
                }
            }
            
            try await document.reference.updateData([
                "role": user.role.rawValue
            ])
        } catch {
            print("Error updating role for \(user.name)")
        }
    }
    
    func updateApproval(for user: AppUser) async {
        print("user Role: \(user.role)")
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
    
    
    func fetchUsers() async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .getDocuments()
            
            let users = snapshot.documents.compactMap { doc -> AppUser? in
                try? doc.data(as: AppUser.self)
            }
            DispatchQueue.main.async {
                self.users = users
            }
        } catch {
            print("Error fetching users: \(error)")
        }
    }
    
    func fetchPendingUsers() async {
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
        let festivalTeamsRef = db.collection("festivalTeams")
        let teamsRef = db.collection("teams")

        festivalTeamsRef.whereField("name", isEqualTo: teamName).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding team \(teamName): \(error)")
                return
            }

            guard let document = snapshot?.documents.first else {
                print("No team found with name: \(teamName)")
                return
            }

            let docRef = festivalTeamsRef.document(document.documentID)
            var performers = document.data()["performers"] as? [String] ?? []

            // Only add if not already present
            if !performers.contains(performerName) {
                performers.append(performerName)

                // ✅ Update festivalTeams
                docRef.updateData(["performers": performers]) { error in
                    if let error = error {
                        print("Error updating performers for festival team \(teamName): \(error)")
                    } else {
                        print("✅ Successfully added performer \(performerName) to festivalTeams")

                        // ✅ Also update the main teams collection
                        teamsRef.whereField("name", isEqualTo: teamName).getDocuments { teamSnapshot, error in
                            if let error = error {
                                print("Error finding team in teams collection: \(error)")
                                return
                            }

                            guard let teamDoc = teamSnapshot?.documents.first else {
                                print("No team found with name \(teamName) in teams collection")
                                return
                            }

                            let teamDocRef = teamsRef.document(teamDoc.documentID)
                            teamDocRef.updateData(["performers": performers]) { error in
                                if let error = error {
                                    print("Error updating performers for team \(teamName) in teams collection: \(error)")
                                } else {
                                    print("✅ Successfully synced performer \(performerName) to teams collection")
                                }
                            }
                        }
                    }
                }
            } else {
                print("⚠️ Performer \(performerName) is already on the team \(teamName)")
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
        self.teams = []
        
        do {
            FirebaseManager.shared.loadFestivalTeamsWithPerformances { teams in
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
                (self.unBooked, self.underBooked, self.fullyBooked, self.overBooked) = self.makeShowGroups(performances: self.performances)
            }
        } catch {
            print("No previous data found or failed to load:", error)
        }
    }
    
    func loadTeams() {
        let db = Firestore.firestore()

        db.collection("teams").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error loading teams: \(error.localizedDescription)")
                return
            }

            // ✅ compactMap allows `nil` returns inside
            let fetchedTeams: [Team] = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let name = data["name"] as? String,
                      let performers = data["performers"] as? [String] else {
                    return nil
                }

                // Use Firestore’s document ID as the team’s id
                return Team(
                    name: name,
                    id: document.documentID,
                    performers: performers
                )
            } ?? []

            DispatchQueue.main.async {
                self.teams = fetchedTeams
                print("✅ Loaded \(fetchedTeams.count) teams from Firestore")
            }
        }
    }
    
    
    func createPerformance(id: String, teamName: String, performerIds: [String], dates: [Date]) {
        FirebaseManager.shared.createPerformance(id: id, teamName: teamName, performerIds: performerIds, dates: dates)
        //        FIXME: This loads the teams, but creates duplicates
        loadData()
        loadTeams()
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
    
    
//    TODO: Remove from Teams
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
    
//    Calculate the number of shows at a showTime
    private func makeShowGroups(performances: [Performance]) -> (
        unBooked: [ShowType: [Date]],
        underBooked: [ShowType: [Date]],
        fullyBooked: [ShowType: [Date]],
        overBooked: [ShowType: [Date]]
    ) {
        var unBooked = [ShowType: [Date]]()
        var underBooked = [ShowType: [Date]]()
        var fullyBooked = [ShowType: [Date]]()
        var overBooked = [ShowType: [Date]]()
        
        // 1. Group performances by their showTime
        let groupedByTime = Dictionary(grouping: performances, by: { $0.showTime })
        
        // 2. Count how many performances are at each time
        let showCounts = groupedByTime.mapValues { $0.count }
        
        // 3. Categorize each showTime
        for (showTime, count) in showCounts {
            if let showType = ShowType.dateToShow(date: showTime) {
                if let requiredTeamCount = showType.requiredTeamCount {
                    switch count {
                    case 0:
                        unBooked[showType, default: []].append(showTime)
                    case 1..<requiredTeamCount:
                        underBooked[showType, default: []].append(showTime)
                    case requiredTeamCount:
                        fullyBooked[showType, default: []].append(showTime)
                    default:
                        overBooked[showType, default: []].append(showTime)
                    }
                } else {
                    // special shows: consider unBooked if 0, underBooked otherwise
                    if count == 0 {
                        unBooked[showType, default: []].append(showTime)
                    } else {
                        underBooked[showType, default: []].append(showTime)
                    }
                }
            } else {
                // Unknown or special shows: treat as underBooked
                underBooked[.special, default: []].append(showTime)
            }
        }
        print("unBooked: \(unBooked)\n underBooked: \(underBooked)\n fullyBooked: \(fullyBooked)\n overBooked: \(overBooked)\n")
        return (unBooked, underBooked, fullyBooked, overBooked)
    }
    
    
    func deleteTeam(named teamName: String) {
        // Find all performances in memory for this team
        let teamPerformances = self.performances.filter { $0.teamName == teamName }
        
        // Call deletePerformance on each one
        for performance in teamPerformances {
            self.deletePerformance(performance)
        }
        
        // Delete the team document itself
        let db = Firestore.firestore()
        db.collection("teams")
            .whereField("name", isEqualTo: teamName)
            .getDocuments { snapshot, error in
                guard let document = snapshot?.documents.first, error == nil else {
                    print("No team found or error: \(error?.localizedDescription ?? "unknown")")
                    return
                }
                
                db.collection("teams").document(document.documentID).delete { error in
                    if let error = error {
                        print("Error deleting team \(teamName): \(error)")
                    } else {
                        print("✅ Deleted team \(teamName) from teams collection")
                        DispatchQueue.main.async {
                            self.teams.removeAll { $0.name == teamName }
                        }
                    }
                }
            }
    }
}

