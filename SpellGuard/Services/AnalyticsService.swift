//
//  AnalyticsService.swift
//  SpellGuard
//
//  Lightweight analytics service (logs locally in debug, no-op in release)
//

import Foundation
import AppTrackingTransparency

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
        case .appOpen, .onboardingCompleted, .paywallViewed, .dailyChallengeCompleted:
            return [:]
        case .levelSelected(let level): return ["grade_level": level.rawValue]
        case .gameModeSelected(let mode): return ["game_mode": mode.rawValue]
        case .sessionStarted(let type): return ["session_type": type.rawValue]
        case .sessionCompleted(let score, let accuracy):
            return ["score": score, "accuracy": accuracy]
        case .wordCorrect(let word): return ["word": word]
        case .wordIncorrect(let word): return ["word": word]
        case .subscriptionStarted(let productId): return ["product_id": productId]
        case .subscriptionFailed(let reason): return ["reason": reason]
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

    func initialize() {
        #if DEBUG
        print("[Analytics] Service initialized")
        #endif
    }

    func track(_ event: AnalyticsEvent) {
        #if DEBUG
        print("[Analytics] \(event.name): \(event.parameters)")
        #endif
    }

    func setUserProperty(_ value: String?, forName name: String) {
        #if DEBUG
        print("[Analytics] Set user property \(name): \(value ?? "nil")")
        #endif
    }

    func setUserId(_ userId: String?) {}
}
