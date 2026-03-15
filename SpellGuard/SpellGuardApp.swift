//
//  SpellGuardApp.swift
//  SpellGuard
//
//  Main app entry point with SwiftData, StoreKit 2, and SDK integrations
//

import SwiftUI
import SwiftData

@main
struct SpellGuardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    @State private var appState = AppStateManager()
    @State private var premiumManager = PremiumManager()

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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(premiumManager)
                .onAppear {
                    // Seed word database
                    WordDatabase.shared.seedWordsIfNeeded(modelContext: modelContainer.mainContext)
                    Task {
                        await premiumManager.refreshPremiumStatus()
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

        Task { @MainActor in
            _ = await ATTService.shared.requestIfNeeded()
            await AttributionManager.shared.requestAttributionIfNeeded()
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
