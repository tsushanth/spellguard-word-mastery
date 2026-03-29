//
//  StoreKitManager.swift
//  SpellGuard
//
//  Thin wrapper around PaywallKit StoreManager for the app's purchase flow.
//

import Foundation
import PaywallKit

// MARK: - Purchase State
enum PurchaseState: Equatable {
    case idle
    case purchasing
    case purchased
    case failed(String)
    case pending
    case cancelled
}

// MARK: - App StoreKit Manager
@MainActor
@Observable
final class AppStoreKitManager {
    private let store = StoreManager.shared

    var purchaseState: PurchaseState = .idle
    var errorMessage: String?

    var isPremium: Bool { store.isPremium }

    var subscriptions: [PaywallProduct] {
        store.paywallProducts.filter { $0.period != .lifetime }
            .sorted { $0.price < $1.price }
    }

    var nonConsumables: [PaywallProduct] {
        store.paywallProducts.filter { $0.period == .lifetime }
    }

    // MARK: - Purchase
    func purchase(_ productId: String) async {
        purchaseState = .purchasing
        errorMessage = nil

        let result = await store.purchase(productId: productId)
        switch result {
        case .purchased:
            purchaseState = .purchased
        case .cancelled:
            purchaseState = .cancelled
        case .pending:
            purchaseState = .pending
        case .failed(let error):
            purchaseState = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Restore
    func restorePurchases() async {
        purchaseState = .purchasing
        await store.refreshSubscriptionStatus()
        purchaseState = isPremium ? .purchased : .idle
    }

    func resetState() {
        purchaseState = .idle
        errorMessage = nil
    }
}
