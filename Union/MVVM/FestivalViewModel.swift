import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth

class FestivalViewModel: ObservableObject {
    @Published var festivalTeams = [TeamData]()
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
    /// Adds a performer to a specific team's performances and to the known performers list.
    func addPerformer(named performerName: String, toTeam teamName: String) {
        knownPerformers.insert(performerName)
        
        for i in performances.indices {
            if performances[i].teamName == teamName {
                if !performances[i].performers.contains(performerName) {
                    performances[i].performers.append(performerName)
                }
            }
        }
    }
    
    /// Deletes a performer and removes them from all teams and performances.
    func deletePerformer(named performer: String,  fromTeam teamName: String?) {
        // Iterate through all performances and remove the performer
        if let teamName = teamName {
            for i in performances.indices {
                if performances[i].teamName == teamName {
                    performances[i].performers.removeAll(where: { $0 == performer })
                }
            }
        } else {
//            If the user supplies a team name, this means they are removing the performer from a team and not
//            from the list of all performers
            // Remove the performer from the main list of known performers
            knownPerformers.remove(performer)
            
            for i in performances.indices {
                performances[i].performers.removeAll(where: { $0 == performer })
            }
            
            // Delete the associated image from the file system
            deleteImage(for: performer)
        }
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
//            TODO: replace json data with firebase data.
//            Start with the knownPerformers, as it's simple
            FirebaseManager.shared.loadFestivalTeams { teams in
                // Use the teams array here
                self.festivalTeams = teams
            }

            for team in festivalTeams {
                print("team: \(team)")
                for showInstance in team.showTimes {
                    print("showInstance: \(showInstance)")
                    let show = Performance(teamName: team.teamName, showTime: showInstance, performers: team.performers)
                    self.performances.append(show)
                }
            }
            print("performances: \(performances)")
//            FIXME:
            self.knownPerformers = loadKnownPerformers(performances: self.performances)
            
//            self.performances = decoded.performances
            self.knownPerformers = Set(decoded.knownPerformers)
            print("Data loaded successfully")
        } catch {
            print("No previous data found or failed to load:", error)
        }
    }
    
    func createPerformance(id: String, teamName: String, performerIds: [String], dates: [Date]) {
        FirebaseManager.shared.createPerformance(id: id, teamName: teamName, performerIds: performerIds, dates: dates)
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
}

