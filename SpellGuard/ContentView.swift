//
//  ContentView.swift
//  SpellGuard
//
//  Root content view - handles routing between onboarding and main app
//

import SwiftUI

// MARK: - Content View
struct ContentView: View {
    @Environment(AppStateManager.self) private var appState
    @Environment(PremiumManager.self) private var premiumManager

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut, value: appState.hasCompletedOnboarding)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            SpellingBeeView()
                .tabItem {
                    Label("Practice", systemImage: "b.circle.fill")
                }
                .tag(1)

            SpellGuardProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(2)


            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}
