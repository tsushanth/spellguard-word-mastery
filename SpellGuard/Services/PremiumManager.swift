//
//  PremiumManager.swift
//  SpellGuard
//
//  Premium status management with RevenueCat placeholder
//

import Foundation
import StoreKit

// MARK: - Premium Manager
@MainActor
@Observable
final class PremiumManager {
    private(set) var isPremium: Bool = false
    private(set) var isLoading: Bool = false
    private let userDefaults = UserDefaults.standard
    private let premiumKey = "com.appfactory.spellguard.isPremium"

    // RevenueCat placeholder key
    private let revenueCatAPIKey = "appl_PLACEHOLDER_KEY"

    init() {
        isPremium = userDefaults.bool(forKey: premiumKey)
    }

    // MARK: - Refresh Status
    func refreshPremiumStatus() async {
        isLoading = true
        // TODO: Purchases.shared.getCustomerInfo { customerInfo, error in ... }
        // For now, rely on StoreKit directly
        await checkStoreKitEntitlements()
        isLoading = false
    }

    private func checkStoreKitEntitlements() async {
        var hasPremium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    hasPremium = true
                    break
                }
            }
        }
        setPremiumStatus(hasPremium)
    }

    func setPremiumStatus(_ premium: Bool) {
        isPremium = premium
        userDefaults.set(premium, forKey: premiumKey)
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
