//
//  UpcomingShowPushTestView.swift
//  Union
//
//  Created by Graham Nadel on 12/8/25.
//

import Foundation
import SwiftUI

struct UpcomingShowPushTestView: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Button("UpcomingShowPushTestView") {
            let shows = getShows()
            print("\(shows.count) upcoming shows")
            Task {
                if let fcmToken = authViewModel.fcmToken {
                    for show in shows {
                        try await sendPushViaFunction(fcmToken: fcmToken, title: show.teamName, body: "\(show.showTime)")
                    }
                } else {
                    print("Could not find FCM token")
                }
            }
        }
    }
    
    private func getShows() -> [Performance] {
        let date = Date()
        let timeWindow = Calendar.current.date(byAdding: .day, value: 7, to: date)!
        let upcomingShowsInWindow = scheduleViewModel.performances.filter { $0.showTime >= date && $0.showTime <= timeWindow }
        return upcomingShowsInWindow
    }
    
    func sendPushViaFunction(fcmToken: String, title: String, body: String) async throws {
        guard let url = URL(string: "https://us-central1-unioncomedy-2d46f.cloudfunctions.net/sendPush") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyDict: [String: Any] = [
            "token": fcmToken,
            "title": title,
            "body": body
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResp = response as? HTTPURLResponse {
            print("Notification sent, status code:", httpResp.statusCode)
        }
    }
}
