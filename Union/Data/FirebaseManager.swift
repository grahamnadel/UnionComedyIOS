import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    
    let db = Firestore.firestore()
    
    var votes: [String: Int] = [:]
    
    func voteForTeam(_ teamName: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("votes").document(uid).setData([
            "team": teamName,
            "timestamp": FieldValue.serverTimestamp()
        ]) { error in
            if let e = error {
                print("Vote error: \(e)")
            } else {
                print("Voted for", teamName)
            }
        }
    }
    
    func listenToVoteCounts(_ onUpdate: @escaping ([String: Int]) -> Void) {
        db.collection("votes")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to votes: \(error.localizedDescription)")
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    print("No documents in votes collection snapshot")
                    onUpdate([:])  // send empty counts if no docs
                    return
                }
                
                let counts = docs.compactMap { $0.data()["team"] as? String }
                    .reduce(into: [String: Int]()) {
                        $0[$1, default: 0] += 1
                    }
                print("Updated vote counts:", counts)
                onUpdate(counts)
            }
    }
    
    func resetVotes() {
        let votesRef = db.collection("votes")
        
        votesRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error getting vote documents: \(error)")
                return
            }
            
            for document in snapshot?.documents ?? [] {
                votesRef.document(document.documentID).delete { err in
                    if let err = err {
                        print("Error deleting vote: \(err)")
                    } else {
                        print("Deleted vote for \(document.documentID)")
                    }
                }
            }
        }
    }
    
//    FIXME: could the problem be with empties?
    func checkForExistingTeam(teamName: String, completion: @escaping (Bool) -> Void) {
        db.collection("festivalTeams")
            .whereField("name", isEqualTo: teamName)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking team name: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                let exists = !(snapshot?.documents.isEmpty ?? true)
                completion(exists)
            }
        
        db.collection("teams")
            .whereField("name", isEqualTo: teamName)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking team name: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                let exists = !(snapshot?.documents.isEmpty ?? true)
                completion(exists)
            }
    }
    
    
    //    Check to see if there are any performers not in the Performers collection. If not, add them
    func checkForExistingPerformers(for performerNames: [String]) {
        let db = Firestore.firestore()
        let performersRef = db.collection("performers")
        for name in performerNames {
            performersRef.whereField("name", isEqualTo: name).getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking for performer: \(name) in performers collection. Error: \(error)")
                    return
                }
                
                if let documents = snapshot?.documents, documents.isEmpty == false {
                    print("Performer \(name) exists")
                } else {
//                    Performer not found
                    let newPerformerData: [String: Any] = [
                        "name": name,
                        "bio": "",
                        "url": ""
                    ]
                    
                    performersRef.addDocument(data: newPerformerData) { error in
                        if let error = error {
                            print("Error adding performer \(name). Error: \(error)")
                        } else {
                            print("Successfully added \(name) to performers collection")
                        }
                    }
                }
            }
        }
    }
    
    
    func createPerformance(id: String, teamName: String, performerIds: [String], dates: [Date], isFestivalShow: Bool) {
        checkForExistingTeam(teamName: teamName) { exists in
            if exists {
                self.db.collection("festivalTeams").whereField("name", isEqualTo: teamName).getDocuments { snapshot, error in
                    if let error = error {
                        print("❌ Error finding team: \(error)")
                        return
                    }

                    guard let document = snapshot?.documents.first else {
                        print("⚠️ No document found for team: \(teamName)")
                        return
                    }

                    let docRef = self.db.collection("festivalTeams").document(document.documentID)

                    // Convert Date array to Firestore Timestamp array
                    let timestamps = dates.map { Timestamp(date: $0) }
//FIXME: debug
//                    2:00
                    print("DEBUG dates going into createPerformance: \(dates)")
                    print("DEBUG timestamps in createPerformance: \(timestamps)")
                    docRef.updateData([
                        "showTimes": FieldValue.arrayUnion(timestamps)
                    ]) { error in
                        if let error = error {
                            print("❌ Failed to update showTimes: \(error)")
                        } else {
                            print("✅ Successfully added dates to team \(teamName)")
                        }
                    }
                }
            } else {
                print("Team not found")
                //FIXME: debug
                print("DEBUG dates going into createPerformance for team not found: \(dates)")
                
                self.db.collection("festivalTeams").document(id).setData([
                    "name": teamName,
                    "performers": performerIds,
                    "showTimes": dates,
                    "id": id,
                    "isFestivalShow": isFestivalShow
                ]) { error in
                    if let error = error {
                        print("Error writing team: \(error)")
                    } else {
                        print("Team successfully written!")
                    }
                }
//                Add any mising performers to performers collection
                self.checkForExistingPerformers(for: performerIds)
            }
        }
        self.createTeam(teamName: teamName, performers: performerIds)
    }
    
    func createTeam(teamName: String, performers: [String]) {
        print("Called createTeam")
            // 1. Check if a team with this name already exists in the "teams" collection
            db.collection("teams")
                .whereField("name", isEqualTo: teamName)
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error checking for existing team in 'teams' collection: \(error)")
                        return
                    }

                    // 2. If documents are found, the team already exists. Do not create a duplicate.
                    if !(snapshot?.documents.isEmpty ?? true) {
                        print("⚠️ Team '\(teamName)' already exists in the 'teams' collection. Skipping creation.")
                        return
                    }
                    
                    // 3. If no documents are found, proceed with creating the new team
                    let id = UUID().uuidString
                    self.db.collection("teams").document(id).setData([
                        "name": teamName,
                        "performers": performers
                    ]) { error in
                        if let error = error {
                            print("Error writing team to 'teams' collection: \(error)")
                        } else {
                            print("✅ Team '\(teamName)' successfully written to 'teams' collection!")
                        }
                    }
                }
        }
    
    func loadFestivalPerformers(completion: @escaping (Set<String>) -> Void ) {
        db.collection("performers").getDocuments { snapshot, error in
            if let error = error {
                print("Error loading performers: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found for performers")
                completion([])
                return
            }
            var performers: Set<String> = []
            for doc in documents {
                let data = doc.data()
                let id = doc.documentID
                let name = data["name"] as? String ?? "Unknown"
                performers.insert(name)
            }
            completion(performers)
        }
    }
    
    func loadFestivalTeamsWithPerformances(completion: @escaping ([TeamData]) -> Void) {
        db.collection("festivalTeams").getDocuments { (snapshot, error) in
            if let error = error {
                print("❌ Error loading teams: \(error.localizedDescription)")
                completion([]) // Return an empty array on error
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                completion([])
                return
            }
            
            var festivalTeams = [TeamData]()
            
            for doc in documents {
                let data = doc.data()
                let id = doc.documentID
                let name = data["name"] as? String ?? "Unknown"
                let performers = data["performers"] as? [String] ?? []
                let isFestivalShow = data["isFestivalShow"] as? Bool ?? false
                
                if let timestampArray = data["showTimes"] as? [Timestamp] {
                    let showTimes = timestampArray.map { $0.dateValue() }
//                    FIXME: debug
//                    1:00
                    print("DEBUG loadFestivalTeamsWithPerformances dateValue: \(showTimes)")
//                    FIXME: load the data in a way that I can designate isFestivalShow dates. Change this to loading an array of Performances. 
                    
                    festivalTeams.append(TeamData(id: id, teamName: name, showTimes: showTimes, performers: performers))
                } else {
                    print("⚠️ error loading showTimes for team: \(name)")
                }
            }
            completion(festivalTeams)
        }
    }
    func loadPerformances(completion: @escaping ([TeamData]) -> Void) {
        db.collection("festivalTeams").getDocuments { (snapshot, error) in
            if let error = error {
                print("❌ Error loading teams: \(error.localizedDescription)")
                completion([]) // Return an empty array on error
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                completion([])
                return
            }
            
            var festivalTeams = [TeamData]()
            
            for doc in documents {
                let data = doc.data()
                let id = doc.documentID
                let name = data["name"] as? String ?? "Unknown"
                let performers = data["performers"] as? [String] ?? []
                let isFestivalShow = data["isFestivalShow"] as? Bool ?? false
                
                if let timestampArray = data["showTimes"] as? [Timestamp] {
                    let showTimes = timestampArray.map { $0.dateValue() }
//                    FIXME: debug
//                    1:00
                    print("DEBUG loadFestivalTeamsWithPerformances dateValue: \(showTimes)")
//                    FIXME: load the data in a way that I can designate isFestivalShow dates. Change this to loading an array of Performances.
                    
                    festivalTeams.append(TeamData(id: id, teamName: name, showTimes: showTimes, performers: performers))
                } else {
                    print("⚠️ error loading showTimes for team: \(name)")
                }
            }
            completion(festivalTeams)
        }
    }
}
