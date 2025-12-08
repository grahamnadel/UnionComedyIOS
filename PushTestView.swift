//
//  PushNotificationTest.swift
//  Union
//
//  Created by Graham Nadel on 11/19/25.
//

import Foundation
import SwiftUI

class PushNotificationManager: ObservableObject {
    private let functionURL = "https://us-central1-unioncomedy-2d46f.cloudfunctions.net/sendPush"
    private let fcmToken = "dVRWreiUcEaWqVoVOVIHUh:APA91bHQC2hlF572RJ4nn7DTyCHveMBHWFXDP_9lHvdOrpvXm36m1HKlqZdl8P0d7XSHioApHJkjmN2Gj2A8kvFJKUh3LNFjyNaCujzyxR6KSi_VyPMPhDs"
    
    func sendPush() {
        guard let url = URL(string: functionURL) else { return }

        let body: [String: Any] = ["token": fcmToken]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { print("Error:", error); return }
            if let response = response as? HTTPURLResponse { print("Status:", response.statusCode) }
            if let data = data { print("Response:", String(data: data, encoding: .utf8) ?? "") }
        }.resume()
    }
}


struct PushTestView: View {
    let functionURL = "https://us-central1-unioncomedy-2d46f.cloudfunctions.net/sendPush"
    @State private var fcmToken = "dVRWreiUcEaWqVoVOVIHUh:APA91bHQC2hlF572RJ4nn7DTyCHveMBHWFXDP_9lHvdOrpvXm36m1HKlqZdl8P0d7XSHioApHJkjmN2Gj2A8kvFJKUh3LNFjyNaCujzyxR6KSi_VyPMPhDs" 
    @State private var title = "Hello!"
    @State private var textBody = "This is a custom notification"

    var body: some View {
        VStack(spacing: 16) {
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Body", text: $textBody)
                .textFieldStyle(.roundedBorder)
            TextField("FCM Token", text: $fcmToken)
                .textFieldStyle(.roundedBorder)

            Button("Send Push Notification") {
                sendPush()
            }
            .padding()
        }
        .padding()
    }

    func sendPush() {
        guard let url = URL(string: functionURL) else { return }

        let bodyDict: [String: Any] = [
            "token": fcmToken,
            "title": title,
            "body": textBody
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDict)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { print("Error:", error); return }
            if let response = response as? HTTPURLResponse { print("Status:", response.statusCode) }
            if let data = data { print("Response:", String(data: data, encoding: .utf8) ?? "") }
        }.resume()
    }
}
