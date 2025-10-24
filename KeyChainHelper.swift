//
//  KeyChainHelper.swift
//  Union
//
//  Created by Graham Nadel on 10/23/25.
//

import Foundation
import Security

struct KeychainHelper {
    static func save(email: String, password: String) {
        let creds = ["email": email, "password": password]
        if let data = try? JSONEncoder().encode(creds) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "userCredentials",
                kSecValueData as String: data
            ]
            SecItemDelete(query as CFDictionary) // Remove old if exists
            SecItemAdd(query as CFDictionary, nil)
            print("Credentials saved securely in Keychain")
        }
    }

    static func load() -> (email: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userCredentials",
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            if let creds = try? JSONDecoder().decode([String: String].self, from: data),
               let email = creds["email"], let password = creds["password"] {
                return (email, password)
            }
        }
        return nil
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userCredentials"
        ]
        SecItemDelete(query as CFDictionary)
        print("Credentials cleared from Keychain")
    }
}
