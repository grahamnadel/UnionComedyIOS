//
//  AppDelegate.swift
//  Union
//
//  Created by Graham Nadel on 11/18/25.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//             Set up push notification handling
            self.setupPushNotifications(application: application)
            
            print("Your code here")
            return true
        }
    
    func setupPushNotifications(application: UIApplication) {
        
        // Set up UNUserNotificationCenterDelegate
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        // Register with APNs
        application.registerForRemoteNotifications()
        
        // Set Messaging Delegate (optional, but recommended for FCM token retrieval)
        Messaging.messaging().delegate = self
    }
    
    // This is the APNs token received from Apple
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass the APNs token to FCM
        Messaging.messaging().apnsToken = deviceToken
        print("APNs token retrieved: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    }

    // This is the FCM registration token (which FCM uses to route messages)
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        // TODO: If you have a backend, send this token to your server
        // so it can send messages to this specific device.
        let data = ["token": fcmToken]
        print("FCM Token data sent to backend: \(data)")
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
            } else if let token = token {
                print("FCM token: \(token)")
                // Save this token to Firestore for the current user
                self.saveTokenToFirestore(token)
            }
        }
    }
    
    func saveTokenToFirestore(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).setData(["fcmToken": token], merge: true) { error in
            if let error = error {
                print("Error saving FCM token:", error)
            } else {
                print("FCM token saved successfully for user \(uid)")
            }
        }
    }

    
    // Optional: Handle foreground notifications (show alerts when app is open)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.banner, .sound, .badge])
    }
}

