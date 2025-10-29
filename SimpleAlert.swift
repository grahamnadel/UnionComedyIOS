//
//  SimpleAlert.swift
//  Union
//
//  Created by Graham Nadel on 10/29/25.
//

import Foundation
import SwiftUI

struct SimpleAlert {
    static func confirmDeletion(
        title: String = "Delete?",
        message: String = "Are you sure you want to delete this item?",
        confirmText: String = "Delete",
        cancelText: String = "Cancel",
        confirmAction: @escaping () -> Void
    ) -> Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            primaryButton: .destructive(Text(confirmText), action: confirmAction),
            secondaryButton: .cancel(Text(cancelText))
        )
    }
    
    static func info(title: String, message: String, dismissText: String = "OK") -> Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text(dismissText))
        )
    }
}
