import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var role: UserRole
    var approved: Bool
}
