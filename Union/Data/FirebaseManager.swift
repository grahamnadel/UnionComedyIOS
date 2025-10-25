import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    
    let db = Firestore.firestore()
    
    var votes: [String: Int] = [:]
    
    private init() {
//        Auth.auth().signInAnonymously { result, error in
//            if let e = error {
//                print("Auth error: \(e)")
//            } else {
//                print("Signed in anonymously as UID: \(result?.user.uid ?? "")")
//            }
//        }
    }
    
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
    }
    
    
    //    func checkForExistingPerformers(performerName: String, completion: @escaping (Bool) -> Void) {
    //        db.collection("performers")
    //            .whereField("name", isEqualTo: performerName)
    //            .getDocuments { snapshot, error in
    //                if let error = error {
    //                    print("Error checking performer name: \(error.localizedDescription)")
    //                    completion(false)
    //                    return
    //                }
    //
    //                let exists = !(snapshot?.documents.isEmpty ?? true)
    //                completion(exists)
    //            }
    //    }
    
    
    //    Check to see if there are any performers not in the Performers collection. If not, add them
    func checkForExistingPerformers(for performerNames: [String]) {
        let db = Firestore.firestore()
        let performersRef = db.collection("performers")
        for name in performerNames {
            performersRef.whereField("name", isEqualTo: name).getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking for performer: \(name) in performers collection")
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
                            print("Error adding performer \(name)")
                        } else {
                            print("Successfully added \(name) to performers collection")
                        }
                    }
                }
            }
        }
    }
    
    
    func createPerformance(id: String, teamName: String, performerIds: [String], dates: [Date]) {
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
                
                self.db.collection("festivalTeams").document(id).setData([
                    "name": teamName,
                    "performers": performerIds,
                    "showTimes": dates,
                    "id": id
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
//                TODO: above, do I want to make a struct to handle performers?
//                Later task
            }
            completion(performers)
        }
    }
    
    func loadFestivalTeams(completion: @escaping ([TeamData]) -> Void) {
//        TODO: Issue for loading performers is that it gets teh performers from those festivalTeams, without checking performers
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
                
                if let timestampArray = data["showTimes"] as? [Timestamp] {
                    let showTimes = timestampArray.map { $0.dateValue() }
                    festivalTeams.append(TeamData(id: id, teamName: name, showTimes: showTimes, performers: performers))
                } else {
                    print("⚠️ error loading showTimes for team: \(name)")
                }
            }
            completion(festivalTeams)
        }
    }
}
