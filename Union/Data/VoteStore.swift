import FirebaseFirestore
import FirebaseFirestoreCombineSwift // (optional for Combine support)
import FirebaseAuth

struct Vote: Codable, Identifiable {
    @DocumentID var id: String?  // Optional Firestore document ID
    var option: String
}

class VoteStore: ObservableObject {
    @Published var vote: Vote?
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func listenToVote() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener = db.collection("votes").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching vote: \(error)")
                return
            }
            if let snapshot = snapshot, snapshot.exists {
                do {
                    self.vote = try snapshot.data(as: Vote.self)
                } catch {
                    print("Error decoding vote: \(error)")
                }
            } else {
                self.vote = nil
            }
        }
    }

    func voteFor(option: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let vote = Vote(id: uid, option: option)
        
        // Use the completion handler to check for errors
        do {
            try db.collection("votes").document(uid).setData(from: vote) { error in
                print("Error in voteFor: \(String(describing: error))")
            }
        } catch {
            print("error encoding vote: \(vote)")
        }
    }


    deinit {
        listener?.remove()
    }
}
