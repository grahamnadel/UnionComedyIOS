//
//  BiographyView.swift
//  Union
//
//  Created by Graham Nadel on 10/24/25.
//

import Foundation
import SwiftUI

struct BiographyView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    var performer: String
    @State private var biographyText = ""
    @State private var isSavingBio = false
    
    var body: some View {
        Group {
            if authViewModel.name == performer {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Biography")
                        .font(.headline)
                    
                    TextEditor(text: $biographyText)
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Spacer()
                        if isSavingBio {
                            ProgressView()
                        } else {
                            Button("Save Bio") {
                                Task {
                                    await saveBiography()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if !biographyText.isEmpty {
                        Text("Biography")
                            .font(.headline)
                        Text(biographyText)
                            .frame(maxWidth: .infinity)
                            .padding(6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                .padding(.horizontal)
            }
        }
        .padding(.top)
        .onAppear {
            Task {
                await loadBiography()
            }
        }
    }
    
    
    // MARK: - Biography loading/saving
    
    private func loadBiography() async {
        if let bio = await scheduleViewModel.fetchBiography(for: performer) {
            await MainActor.run {
                biographyText = bio
                print("loaded bio: \(biographyText)")
            }
        }
    }
    
    private func saveBiography() async {
        guard !biographyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSavingBio = true
        await scheduleViewModel.saveBiography(for: performer, bio: biographyText)
        isSavingBio = false
    }
    
}
