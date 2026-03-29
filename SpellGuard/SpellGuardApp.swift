//
//  SpellGuardApp.swift
//  SpellGuard
//
//  Main app entry point with SwiftData, PaywallKit, and SDK integrations
//

import SwiftUI
import SwiftData
import PaywallKit

@main
struct SpellGuardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    @State private var appState = AppStateManager()

    init() {
        do {
            let schema = Schema([
                Word.self,
                WordProgress.self,
                SpellingChallenge.self,
                GameSession.self,
                DailyChallenge.self,
                LeaderboardEntry.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Configure PaywallKit StoreManager
        PremiumManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(PremiumManager.shared)
                .onAppear {
                    WordDatabase.shared.seedWordsIfNeeded(modelContext: modelContainer.mainContext)
                    Task {
                        await PremiumManager.shared.refreshPremiumStatus()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if DEBUG
        print("[AppDelegate] SpellGuard launched")
        #endif

        Task { @MainActor in
            AnalyticsService.shared.initialize()
            AnalyticsService.shared.track(.appOpen)
        }

        return true
    }
}

// MARK: - App State Manager
@MainActor
@Observable
class AppStateManager {
    var hasCompletedOnboarding: Bool = false
    var isAuthenticated: Bool = false

    private let userDefaults = UserDefaults.standard
    private let onboardingKey = "com.appfactory.spellguard.hasCompletedOnboarding"

    init() {
        hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaults.set(false, forKey: onboardingKey)
    }
}
