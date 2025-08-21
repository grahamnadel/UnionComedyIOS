//
//  MainView.swift
//  Union
//
//  Created by Graham Nadel on 6/18/25.
//

import Foundation
import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: ViewModel
    @ObservedObject var festivalViewModel: FestivalViewModel
    
    @State private var showPasswordPrompt = false
    @State private var showSettings = false
    @State private var password = ""
    @State private var passwordError = false
    
    init(_ viewModel: ViewModel, _ festivalViewModel: FestivalViewModel) {
        self.viewModel = viewModel
        self.festivalViewModel = festivalViewModel
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                VStack {
                    VoteView(viewModel: viewModel)
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
                    SettingsView(viewModel)
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
            
            FestivalView(festivalViewModel: festivalViewModel)
                .tabItem {
                    Label("Festival", systemImage: "chart.bar.fill")
                }
        }
    }
}
