import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage


class ScheduleViewModel: ObservableObject {
    @Published var festivalTeams = [TeamData]()
    @Published var performances: [Performance] = []
    //    TODO: fix how teams is populated
    @Published var teams: [Team] = []
    @Published var knownPerformers: Set<String> = []
    @Published var isAdminOwner = false
    
    //    Arrays of the showstypes and dates
    //    I want to list all the improperly booked shows
    @Published var unBooked: [ShowType: [Date]] = [:]
    @Published var underBooked: [ShowType: [Date]] = [:]
    @Published var fullyBooked: [ShowType: [Date]] = [:]
    @Published var overBooked: [ShowType: [Date]] = [:]
    
    @Published var pendingUsers: [AppUser] = []
    @Published var users: [AppUser] = []
    
    @Published var festivalStartDate: Date?
    @Published var festivalEndDate: Date?
    @Published var festivalLocation: String?
    
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
        loadFestivalDatesAndLocation { start, end, location in
            self.festivalStartDate = start
            self.festivalEndDate = end
            self.festivalLocation = location
        }
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
            let bio = document.data()["bio"] as? String ?? ""
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
    
    //    Change the team too and from a house team
    func updateTeamType(teamName: String, isHouseTeam: Bool) {
        let db = Firestore.firestore()
        let teamsRef = db.collection("teams")
        
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
            docRef.updateData(["houseTeam": isHouseTeam]) { error in
                if let error = error {
                    print("Error updating performers for festival team \(teamName): \(error)")
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
        let now = Date()
        // Clear existing data before loading new data
        Task { @MainActor in
            self.festivalTeams = []
            self.performances = []
            self.knownPerformers = []
        }
        
        do {
            FirebaseManager.shared.loadFestivalTeamsWithPerformances { teams in
                print("teams: \(teams)")
                self.festivalTeams = teams
                
                for team in self.festivalTeams {
                    print("team: \(team)")
                    for showInstance in team.showTimes {
                        print("showInstance: \(showInstance)")
                        let show = Performance(teamName: team.teamName, showTime: showInstance, performers: team.performers)
                        //                        FIXME: does it load correctly?
                        //                        1:00 ** one of these is for 2:00. WTF!
                        print("Debug: showInstance: \(showInstance)")
                        //                        Only show upcoming shows
                        if show.showTime > now {
                            self.performances.append(show)
                        }
                        print("performances: \(self.performances)")
                    }
                }
                
                //                self.loadKnownPerformers { performers in
                //                    self.knownPerformers = performers
                //                    print("known performers: \(self.knownPerformers)")
                //                }
                (self.unBooked, self.underBooked, self.fullyBooked, self.overBooked) = self.makeShowGroups(performances: self.performances)
            }
        } catch {
            print("No previous data found or failed to load:", error)
        }
    }
    
    func loadTeams() {
        Task { @MainActor in
            self.teams = []
        }
        let db = Firestore.firestore()
        
        db.collection("teams").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error loading teams: \(error.localizedDescription)")
                return
            }
            
            // ✅ compactMap allows `nil` returns inside
            //            TODO: find where teams are saved and add indie/house team bool
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
                self.knownPerformers = Set(fetchedTeams.flatMap { $0.performers })
                print("✅ Loaded \(fetchedTeams.count) teams from Firestore")
            }
        }
    }
    
    func createPerformance(id: String, teamName: String, performerIds: [String], dates: [Date]) {
        FirebaseManager.shared.createPerformance(id: id, teamName: teamName, performerIds: performerIds, dates: dates)
        loadData()
        loadTeams()
    }
    
    
    //    TODO: Remove from Teams
    func removePerformerFromFirebase(teamName: String?, performerName: String) {
        let db = Firestore.firestore()
        let teamsRef = db.collection("teams")
        let performersRef = db.collection("performers")
        let festivalTeamsRef = db.collection("festivalTeams")
        
        // 1️⃣ Delete performer documents from the "performers" collection
        performersRef.whereField("name", isEqualTo: performerName).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching performers: \(error)")
                return
            }
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("⚠️ Performer '\(performerName)' not found in performers collection")
                return
            }
            
            for document in documents {
                performersRef.document(document.documentID).delete { error in
                    if let error = error {
                        print("❌ Error deleting performer \(performerName): \(error.localizedDescription)")
                    } else {
                        print("✅ Deleted performer '\(performerName)' (ID: \(document.documentID)) from performers")
                    }
                }
            }
        }
        
        // 2️⃣ Remove performer name from "teams" collection
        teamsRef.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching teams: \(error)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            for document in documents {
                var performers = document.data()["performers"] as? [String] ?? []
                let originalCount = performers.count
                performers.removeAll { $0 == performerName }
                
                if performers.count != originalCount {
                    teamsRef.document(document.documentID).updateData(["performers": performers]) { error in
                        if let error = error {
                            print("❌ Error updating team \(document.documentID): \(error)")
                        } else {
                            print("✅ Removed '\(performerName)' from team \(document.data()["name"] ?? "Unknown") in teams")
                        }
                    }
                }
            }
        }
        
        // 3️⃣ Remove performer name from "festivalTeams" collection
        festivalTeamsRef.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching festivalTeams: \(error)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            for document in documents {
                var performers = document.data()["performers"] as? [String] ?? []
                let originalCount = performers.count
                performers.removeAll { $0 == performerName }
                
                if performers.count != originalCount {
                    festivalTeamsRef.document(document.documentID).updateData(["performers": performers]) { error in
                        if let error = error {
                            print("❌ Error updating festivalTeam \(document.documentID): \(error)")
                        } else {
                            print("✅ Removed '\(performerName)' from festivalTeam \(document.data()["name"] ?? "Unknown")")
                        }
                    }
                }
            }
        }

        // 4️⃣ Refresh UI
        loadData()
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
    
    //    MARK: calculate booking issues
    
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
        
        let upcomingShowDates = getShowDates()
        print("upcomingShowDates: \(upcomingShowDates)")
        
        // 1. Group performances by their showTime
        let groupedByTime = Dictionary(grouping: performances, by: { $0.showTime })
        print("groupedByTime: \(groupedByTime)")
        
        // 2. Count how many performances are at each time
        let showCounts = groupedByTime.mapValues { $0.count }
        print("showCounts: \(showCounts)")
        
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
        
        //            Check to through all upcoming show dats to see which ones are booked so some degree (fully, partially, over). remove all booked dates to get the unbooked ones
        for type in ShowType.allCases {
            print("showType type: \(type)")
            //                all upcoming dates for the showType
            var allDates = upcomingShowDates[type.rawValue]
            print("allDates for upcomingShowDates[\(type)]: upcomingShowDates[\(type.rawValue)]: \(allDates ?? [])\n")
            if let allDates = allDates {
                // Collect all booked dates for this show type
                let bookedDates = (underBooked[type] ?? []) + (fullyBooked[type] ?? []) + (overBooked[type] ?? [])
                let unBookedDates = allDates.filter { !bookedDates.contains($0)}
                unBooked[type] = unBookedDates
            } else {
                print("could not unwrap allDates for \(type.rawValue)")
            }
        }
        
        print("unBooked: \(unBooked)\n underBooked: \(underBooked)\n fullyBooked: \(fullyBooked)\n overBooked: \(overBooked)\n")
        return (unBooked, underBooked, fullyBooked, overBooked)
    }
    
    //    This will calculate if there are shows in the next month that are over, under, or unbooked
    func getShowDates() -> [String: [Date]] {
        let calendar = Calendar.current
        let oneMonth = datesForNextMonth() // your array of all dates
        
        var fridayNightFusionTimes: [Date] = []
        var fridayWeekendShowTimes: [Date] = []
        var saturdayWeekendShowTimes: [Date] = []
        var pickleTimes: [Date] = []
        var cageMatchTimes: [Date] = []
        
        for date in oneMonth {
            switch calendar.component(.weekday, from: date) {
            case 6: // Friday
                if let fusion = calendar.date(bySettingHour: 21, minute: 00, second: 0, of: date) {
                    fridayNightFusionTimes.append(fusion)
                    print("getShowDates: Friday night show time: \(fusion)")
                }
                if let weekendShow = calendar.date(bySettingHour: 19, minute: 30, second: 0, of: date) {
                    fridayWeekendShowTimes.append(weekendShow)
                }
            case 7: // Saturday
                if let weekendShow = calendar.date(bySettingHour: 19, minute: 30, second: 0, of: date) {
                    saturdayWeekendShowTimes.append(weekendShow)
                }
                if let pickle = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: date) {
                    pickleTimes.append(pickle)
                }
            case 1: // Sunday
                if let cageMatch = calendar.date(bySettingHour: 19, minute: 30, second: 0, of: date) {
                    cageMatchTimes.append(cageMatch)
                }
            default:
                break
            }
        }
        
        return ["fridayNightFusion": fridayNightFusionTimes, "fridayWeekendShow": fridayWeekendShowTimes, "saturdayWeekendShow": saturdayWeekendShowTimes, "pickle": pickleTimes, "cageMatch": cageMatchTimes]
    }
    
    
    func datesForNextMonth() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date()) // normalize to start of day
        let numberOfDays = 30
        
        return (0..<numberOfDays).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }
    
    func getBookingDates(for status: BookingStatus) -> [ShowType : [Date]] {
        switch status {
        case .unBooked:
            // Return the raw array
            return unBooked
        case .underBooked:
            // Could return a pre-sorted array here if needed
            return underBooked
        case .booked:
            // Could apply additional filtering
            return fullyBooked
        case .overBooked:
            return overBooked
        }
    }
    
    func saveFestivalDatesAndLocation(start: Date, end: Date, location: String) {
        let db = Firestore.firestore()
        let collection = db.collection("festivalDates")
        
        collection.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching documents: \(error)")
                return
            }
            
            if let document = snapshot?.documents.first {
                // ✅ Update existing festival info
                document.reference.setData([
                    "startDate": Timestamp(date: start),
                    "endDate": Timestamp(date: end),
                    "location": location
                ], merge: true) { error in
                    if let error = error {
                        print("❌ Error updating festival info: \(error)")
                    } else {
                        print("✅ Festival information updated successfully")
                    }
                }
                
            } else {
                // ✅ No document found — create a new one
                collection.addDocument(data: [
                    "startDate": Timestamp(date: start),
                    "endDate": Timestamp(date: end),
                    "location": location
                ]) { error in
                    if let error = error {
                        print("❌ Error creating festival info: \(error)")
                    } else {
                        print("✅ Festival information added successfully")
                    }
                }
            }
        }
    }
    
    func loadFestivalDatesAndLocation(completion: @escaping (Date?, Date?, String?) -> Void) {
        let db = Firestore.firestore()
        let collection = db.collection("festivalDates")
        
        collection.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching festival data: \(error)")
                completion(nil, nil, nil)
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("ℹ️ No festival data found.")
                completion(nil, nil, nil)
                return
            }
            
            let data = document.data()
            
            let startDate = (data["startDate"] as? Timestamp)?.dateValue()
            let endDate = (data["endDate"] as? Timestamp)?.dateValue()
            let location = data["location"] as? String
            
            print("✅ Loaded festival info: start=\(String(describing: startDate)), end=\(String(describing: endDate)), location=\(location ?? "N/A")")
            
            completion(startDate, endDate, location)
        }
    }
}

