//
//  PushNotificationTest.swift
//  Union
//
//  Created by Graham Nadel on 11/19/25.
//

import Foundation
import SwiftUI

struct PushTestView: View {
    let functionURL = "https://us-central1-unioncomedy-2d46f.cloudfunctions.net/sendPush"
    @State private var fcmToken = "dVRWreiUcEaWqVoVOVIHUh:APA91bHQC2hlF572RJ4nn7DTyCHveMBHWFXDP_9lHvdOrpvXm36m1HKlqZdl8P0d7XSHioApHJkjmN2Gj2A8kvFJKUh3LNFjyNaCujzyxR6KSi_VyPMPhDs"

    var body: some View {
        VStack {
            TextField("FCM Token", text: $fcmToken)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button("Send Push") {
                sendPush()
            }
            .padding()
        }
    }

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
