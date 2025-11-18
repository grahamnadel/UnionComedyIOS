////
////  AppDelegate.swift
////  Union
////
////  Created by Graham Nadel on 11/18/25.
////
//
//import Foundation
//import UIKit
//import Firebase
//import FirebaseMessaging
//import UserNotifications
//
//class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
//
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        FirebaseApp.configure()
//        
//        // Request notification permission
//        UNUserNotificationCenter.current().delegate = self
//        requestNotificationPermission(application)
//        
//        Messaging.messaging().delegate = self
//        
//        return true
//    }
//
//    func requestNotificationPermission(_ application: UIApplication) {
//        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
//            print("Notification permission granted: \(granted)")
//        }
//        application.registerForRemoteNotifications()
//    }
//
//    // Pass device token to FCM
//    func application(_ application: UIApplication,
//                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        Messaging.messaging().apnsToken = deviceToken
//        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
//        print("APNs Device Token: \(token)")
//    }
//
//    // FCM token refresh
//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        print("FCM token: \(fcmToken ?? "")")
//        // Send this token to your backend if needed
//    }
//
//    // Handle foreground notifications
//    func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                willPresent notification: UNNotification,
//                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler([.badge, .sound, .banner])
//    }
//}
