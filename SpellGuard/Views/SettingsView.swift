//
//  SettingsView.swift
//  SpellGuard
//
//  App settings view
//

import SwiftUI
import AVFoundation

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumManager.self) private var premiumManager

    @AppStorage("spellguard.notifications.daily") private var dailyNotificationsEnabled = false
    @AppStorage("spellguard.notifications.streak") private var streakNotificationsEnabled = false
    @AppStorage("spellguard.sound.enabled") private var soundEnabled = true
    @AppStorage("spellguard.speech.rate") private var speechRate = 0.5
    @AppStorage("spellguard.username") private var username = ""

    @State private var showingPaywall = false
    @State private var showingResetAlert = false
    @State private var editingUsername = false
    @State private var tempUsername = ""

    var body: some View {
        NavigationStack {
            List {
                // Profile
                Section("Profile") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(username.isEmpty ? "SpellGuard Player" : username)
                                .font(.headline)
                            Text(premiumManager.isPremium ? "Premium Member" : "Free Plan")
                                .font(.caption)
                                .foregroundStyle(premiumManager.isPremium ? .yellow : .secondary)
                        }
                        Spacer()
                        Button("Edit") {
                            tempUsername = username
                            editingUsername = true
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                }

                // Premium
                if !premiumManager.isPremium {
                    Section {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                Text("Upgrade to Premium")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Premium")
                    }
                }

                // Notifications
                Section("Notifications") {
                    Toggle("Daily Challenge Reminder", isOn: $dailyNotificationsEnabled)
                        .onChange(of: dailyNotificationsEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    let granted = await NotificationManager.shared.requestAuthorization()
                                    if granted {
                                        NotificationManager.shared.scheduleDailyChallenge()
                                    } else {
                                        dailyNotificationsEnabled = false
                                    }
                                }
                            } else {
                                NotificationManager.shared.cancelNotification(identifier: "daily.challenge")
                            }
                        }

                    Toggle("Streak Reminders", isOn: $streakNotificationsEnabled)
                }

                // Audio
                Section("Audio & Speech") {
                    Toggle("Sound Effects", isOn: $soundEnabled)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Speech Speed")
                            Spacer()
                            Text(speechRateLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $speechRate, in: 0.1...1.0)
                            .tint(.blue)
                            .onChange(of: speechRate) { _, rate in
                                SpeechEngine.shared.speechRate = AVSpeechUtteranceDefaultSpeechRate * Float(rate)
                            }
                    }
                }

                // About
                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build", value: appBuild)

                    Link(destination: URL(string: "https://kreativekoala.llc/privacy")!) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }

                    Link(destination: URL(string: "https://kreativekoala.llc/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }

                    Button {
                        // Open email
                        if let url = URL(string: "mailto:support@appfactory.dev") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Contact Support", systemImage: "envelope")
                    }

                    Button {
                        if let url = URL(string: "itms-apps://itunes.apple.com/app/id000000000?action=write-review") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Rate SpellGuard", systemImage: "star")
                    }
                }

                // Data
                Section("Data") {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Reset Progress", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .alert("Edit Username", isPresented: $editingUsername) {
            TextField("Username", text: $tempUsername)
            Button("Save") {
                username = tempUsername.trimmingCharacters(in: .whitespaces)
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Reset Progress", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                resetProgress()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all your progress data. This action cannot be undone.")
        }
    }

    private var speechRateLabel: String {
        if speechRate < 0.35 { return "Slow" }
        if speechRate < 0.65 { return "Normal" }
        return "Fast"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private func resetProgress() {
        UserDefaults.standard.removeObject(forKey: "spellguard.streak")
        UserDefaults.standard.removeObject(forKey: "spellguard.longestStreak")
        UserDefaults.standard.removeObject(forKey: "spellguard.lastPracticeDate")
    }
}
