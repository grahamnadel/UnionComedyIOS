//
//  MainView.swift
//  Union
//
//  Created by Graham Nadel on 6/18/25.
//

import Foundation
import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var festivalViewModel: FestivalViewModel
    
    @State private var showPasswordPrompt = false
    @State private var showSettings = false
    @State private var password = ""
    @State private var passwordError = false

    
    var body: some View {
        TabView {
            NavigationStack {
                VStack {
                    VoteView()
                        .tabItem {
                            Label("Vote", systemImage: "figure.boxing")
                        }
                        .navigationTitle("Cage Match")
                        .navigationBarTitleDisplayMode(.large)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            print("Settings tapped")
                            showPasswordPrompt = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
                .sheet(isPresented: $showPasswordPrompt) {
                                    VStack(spacing: 20) {
                                        Text("Enter Admin Password")
                                            .font(.headline)
                                        
                                        SecureField("Password", text: $password)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .padding(.horizontal)
                                        
                                        if passwordError {
                                            Text("Incorrect password")
                                                .foregroundColor(.red)
                                        }

                                        HStack {
                                            Button("Cancel") {
                                                password = ""
                                                showPasswordPrompt = false
                                                passwordError = false
                                            }
                                            .foregroundColor(.red)

                                            Spacer()

                                            Button("Submit") {
                                                if password == viewModel.correctPassword {
                                                    showPasswordPrompt = false
                                                    password = ""
                                                    passwordError = false
                                                    showSettings = true
                                                } else {
                                                    passwordError = true
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .padding()
                                    .presentationDetents([.fraction(0.3)])
                                }
            }
            .tabItem {
                Label("Vote", systemImage: "figure.boxing")
            }
            
            FestivalView()
                .tabItem {
                    Label("Festival", systemImage: "chart.bar.fill")
                }
        }
    }
}
