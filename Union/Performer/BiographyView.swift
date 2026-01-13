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
                // Editable biography for the performer themselves
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Biography")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    ZStack(alignment: .topLeading) {
                        // Custom TextEditor background
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .background(.ultraThinMaterial.opacity(0.3))
                            .cornerRadius(16)
                        
                        TextEditor(text: $biographyText)
                            .frame(height: 140)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                            .padding(12)
                    }
                    .frame(height: 140)
                    
                    HStack {
                        Spacer()
                        if isSavingBio {
                            ProgressView()
                                .tint(.purple)
                        } else {
                            Button {
                                Task {
                                    await saveBiography()
                                }
                            } label: {
                                Text("Save Bio")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.purple,
                                                Color.pink
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            } else {
                // Read-only biography for others viewing
                VStack(alignment: .leading, spacing: 16) {
                    if !biographyText.isEmpty {
                        Text("Biography")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text(biographyText)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .background(.ultraThinMaterial.opacity(0.3))
                                    .cornerRadius(16)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 8)
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
