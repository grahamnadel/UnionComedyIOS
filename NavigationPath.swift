//
//  NavigationPath.swift
//  Union
//
//  Created by Graham Nadel on 11/10/25.
//
import SwiftUI
import Foundation

private struct NavigationPathKey: EnvironmentKey {
    static let defaultValue: Binding<NavigationPath>? = nil
}

extension EnvironmentValues {
    var navigationPath: Binding<NavigationPath>? {
        get { self[NavigationPathKey.self] }
        set { self[NavigationPathKey.self] = newValue }
    }
}
