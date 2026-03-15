//
//  AnalyticsService.swift
//  SpellGuard
//
//  Firebase Analytics + Facebook SDK integration (placeholders)
//

import Foundation

// MARK: - Analytics Events
enum AnalyticsEvent {
    case appOpen
    case onboardingCompleted
    case levelSelected(GradeLevel)
    case gameModeSelected(GameMode)
    case sessionStarted(SessionType)
    case sessionCompleted(score: Int, accuracy: Int)
    case wordCorrect(String)
    case wordIncorrect(String)
    case paywallViewed
    case subscriptionStarted(String)
    case subscriptionFailed(String)
    case dailyChallengeCompleted
    case streakUpdated(Int)
    case signUp(method: String)
    case wordFavorited(String)

    var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .onboardingCompleted: return "onboarding_completed"
        case .levelSelected: return "level_selected"
        case .gameModeSelected: return "game_mode_selected"
        case .sessionStarted: return "session_started"
        case .sessionCompleted: return "session_completed"
        case .wordCorrect: return "word_correct"
        case .wordIncorrect: return "word_incorrect"
        case .paywallViewed: return "paywall_viewed"
        case .subscriptionStarted: return "subscription_started"
        case .subscriptionFailed: return "subscription_failed"
        case .dailyChallengeCompleted: return "daily_challenge_completed"
        case .streakUpdated: return "streak_updated"
        case .signUp: return "sign_up"
        case .wordFavorited: return "word_favorited"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .appOpen: return [:]
        case .onboardingCompleted: return [:]
        case .levelSelected(let level): return ["grade_level": level.rawValue]
        case .gameModeSelected(let mode): return ["game_mode": mode.rawValue]
        case .sessionStarted(let type): return ["session_type": type.rawValue]
        case .sessionCompleted(let score, let accuracy):
            return ["score": score, "accuracy": accuracy]
        case .wordCorrect(let word): return ["word": word]
        case .wordIncorrect(let word): return ["word": word]
        case .paywallViewed: return [:]
        case .subscriptionStarted(let productId): return ["product_id": productId]
        case .subscriptionFailed(let reason): return ["reason": reason]
        case .dailyChallengeCompleted: return [:]
        case .streakUpdated(let count): return ["streak": count]
        case .signUp(let method): return ["method": method]
        case .wordFavorited(let word): return ["word": word]
        }
    }
}

// MARK: - Analytics Service
final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    // MARK: - Initialize
    func initialize() {
        // TODO: FirebaseApp.configure()
        // TODO: FacebookCore SDK init
        print("[Analytics] Service initialized")
    }

    // MARK: - Track Event
    func track(_ event: AnalyticsEvent) {
        #if DEBUG
        print("[Analytics] \(event.name): \(event.parameters)")
        #endif
        // TODO: Analytics.logEvent(event.name, parameters: event.parameters)
        // TODO: AppEvents.shared.logEvent(...)
    }

    // MARK: - User Properties
    func setUserProperty(_ value: String?, forName name: String) {
        #if DEBUG
        print("[Analytics] Set user property \(name): \(value ?? "nil")")
        #endif
        // TODO: Analytics.setUserProperty(value, forName: name)
    }

    func setUserId(_ userId: String?) {
        // TODO: Analytics.setUserID(userId)
    }
}

// MARK: - ATT Service
final class ATTService {
    static let shared = ATTService()
    private init() {}

    func requestIfNeeded() async -> Bool {
        // TODO: AppTrackingTransparency authorization request
        return false
    }
}

// MARK: - Attribution Manager
final class AttributionManager {
    static let shared = AttributionManager()
    private init() {}

    func requestAttributionIfNeeded() async {
        // TODO: AdServices attribution token request
    }
}
