//
//  PremiumManager.swift
//  SpellGuard
//
//  Premium status management via PaywallKit StoreManager
//

import Foundation
import StoreKit
import PaywallKit

// MARK: - Product Identifiers
enum ProductID {
    static let weekly = "com.appfactory.spellguard.subscription.weekly"
    static let monthly = "com.appfactory.spellguard.subscription.monthly"
    static let yearly = "com.appfactory.spellguard.subscription.yearly"
    static let lifetime = "com.appfactory.spellguard.premium.lifetime"

    static var allIDs: [String] {
        [weekly, monthly, yearly, lifetime]
    }
}

// MARK: - Premium Manager
@MainActor
@Observable
final class PremiumManager {
    static let shared = PremiumManager()

    private let store = StoreManager.shared

    var isPremium: Bool { store.isPremium }
    var isLifetime: Bool { store.isLifetime }

    private init() {}

    func configure() {
        store.configure(productIds: ProductID.allIDs)
    }

    func refreshPremiumStatus() async {
        await store.refreshSubscriptionStatus()
    }

    // MARK: - Grade Level Access
    func hasAccessToGradeLevel(_ level: GradeLevel) -> Bool {
        if !level.isPremium { return true }
        return isPremium
    }

    // MARK: - Feature Access
    var canAccessOfflineMode: Bool { isPremium }
    var canAccessSATWords: Bool { isPremium }
    var canAccessACTWords: Bool { isPremium }
    var showsAds: Bool { !isPremium }
    var canAccessAllGameModes: Bool { isPremium }
}
