import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()

    let db = Firestore.firestore()
    
    var votes: [String: Int] = [:]

    private init() {
        Auth.auth().signInAnonymously { result, error in
            if let e = error {
                print("Auth error: \(e)")
            } else {
                print("Signed in anonymously as UID: \(result?.user.uid ?? "")")
            }
        }
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
}
