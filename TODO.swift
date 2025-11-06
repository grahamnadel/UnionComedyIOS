//
//  TODO.swift
//  Union
//
//  Created by Graham Nadel on 10/25/25.
//

import Foundation
// MARK: Check with Client
//  Have bio and detail views for indie performers
//    Separate Union and Indie teams
//  For warnings of over/under booking
//    How far out do they want the warning? Default to 1 month
//  Email blast all indie teams when in need for a team?

// TODO: List

//Priority low to high
// Separate Firebase and scheduleViewModel

// Review and Edit code

// Aesthetics and UI
//    Human Interface Guidelines
//    pending Users/All Users toggle is not user friendly
//  Change colors of showType labels in DatesList

// DEBUG:
//    Changing a performer to audience will not remove them from teams

                                                    // TODAY:
//    Allow pending approval performers to use app as audience
//  Add a festivalShow: Bool to a performance. Highlight these shows in a new color and make it clear they are in a different location than normal

// MARK: Current work:
//  Add a second team button on the addPerformanceView?

//Deleting all performances for a team eliminates team from suggestions
//  show if the performance is for the festival
//Find this:
//FIXME: load the data in a way that I can designate isFestivalShow dates. Change this to loading an array of Performances.




















//MARK: Completed work

// Date: 10/29/25
//    A team in the Teams list without performances will not show the performers
//  When a performer is on a team without performances, it will not say those teams in the performance row view
//  Add deleting for teams
//  Add warnings for deleting
// Rename festivalViewModel to scheduleViewModel
// Organize files

// Date: 10/30/25
//    DEBUG: If someone is a performer and I move them to audience, they remain in the performers list
//    Change syntax: owner to owner

// Date: 10/31/25
//    Auto delete old shows
//      at the least only show future shows



// Auto refresh dates page after adding a new team
//    Make a list of over or under booked Performances in the admin page


//
//FirebaseManager.shared.loadPerformances { teams in
//    print("teams: \(teams)")
//    self.festivalTeams = teams
//    
//    for team in self.festivalTeams {
//        print("team: \(team)")
//        for showInstance in team.showTimes {
//            print("showInstance: \(showInstance)")
////                        FIXME: load the isFestivalShow
//            let show = Performance(teamName: team.teamName, showTime: showInstance, performers: team.performers, isFestivalShow: Bool)
////                        FIXME: does it load correctly?
////                        1:00 ** one of these is for 2:00. WTF!
//            print("Debug: showInstance: \(showInstance)")
////                        Only show upcoming shows
//            if show.showTime > now {
//                self.performances.append(show)
//            }
//            print("performances: \(self.performances)")
//        }
//    }
//    
//    self.loadKnownPerformers { performers in
//        self.knownPerformers = performers
//        print("known performers: \(self.knownPerformers)")
//    }
//    (self.unBooked, self.underBooked, self.fullyBooked, self.overBooked) = self.makeShowGroups(performances: self.performances)
//}
//


//FireBaseManager
//
//func loadPerformances(completion: @escaping ([[Performance]]) -> Void) {
//    db.collection("festivalTeams").getDocuments { (snapshot, error) in
//        if let error = error {
//            print("❌ Error loading teams: \(error.localizedDescription)")
//            completion([]) // Return an empty array on error
//            return
//        }
//        
//        guard let documents = snapshot?.documents else {
//            print("No documents found")
//            completion([])
//            return
//        }
//        
//        var festivalTeamPerformances: [Performance] = [Performance]()
//        var festivalTeams: [[Performance]] = [[]]
//        
//        for doc in documents {
//            let data = doc.data()
//            let id = doc.documentID
//            let name = data["name"] as? String ?? "Unknown"
//            let performers = data["performers"] as? [String] ?? []
//            let isFestivalShow = data["isFestivalShow"] as? Bool ?? false
//            
//            if let timestampArray = data["showTimes"] as? [Timestamp] {
//                let showTimes = timestampArray.map { $0.dateValue() }
//                for time in showTimes {
////                        DO I need the id = id?
//                    festivalTeamPerformances.append(Performance(id: UUID(), teamName: name, showTime: time, performers: performers, isFestivalShow: isFestivalShow))
//                }
//                festivalTeams.append(festivalTeamPerformances)
//                festivalTeamPerformances = []
//            } else {
//                print("⚠️ error loading showTimes for team: \(name)")
//            }
//        }
//        completion(festivalTeams)
//    }
//}
