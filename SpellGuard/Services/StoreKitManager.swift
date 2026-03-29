//
//  StoreKitManager.swift
//  SpellGuard
//
//  Thin wrapper bridging PaywallKit's StoreManager to the app's existing API.
//  Views that referenced `StoreKitManager` now go through here.
//

import Foundation
import StoreKit
import PaywallKit

// MARK: - Purchase State
enum PurchaseState: Equatable {
    case idle
    case loading
    case purchasing
    case purchased
    case failed(String)
    case pending
    case cancelled
    case noNetwork
}

// MARK: - App StoreKit Manager
@MainActor
@Observable
final class AppStoreKitManager {
    private let store = StoreManager.shared

    var purchaseState: PurchaseState = .idle
    var errorMessage: String?

    var isPremium: Bool { store.isPremium }
    var products: [PaywallProduct] { store.paywallProducts }

    var subscriptions: [PaywallProduct] {
        products.filter { $0.product.type == .autoRenewable || $0.product.type == .nonRenewable }
            .sorted { $0.product.price < $1.product.price }
    }

    var nonConsumables: [PaywallProduct] {
        products.filter { $0.product.type == .nonConsumable }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws {
        purchaseState = .purchasing
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await StoreManager.shared.refreshSubscriptionStatus()
                    await transaction.finish()
                    purchaseState = .purchased
                case .unverified:
                    purchaseState = .failed("Verification failed")
                    errorMessage = "Purchase verification failed."
                }
            case .userCancelled:
                purchaseState = .cancelled
            case .pending:
                purchaseState = .pending
            @unknown default:
                purchaseState = .failed("Unknown error")
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Restore
    func restorePurchases() async {
        purchaseState = .loading
        do {
            try await AppStore.sync()
            await store.refreshSubscriptionStatus()
            purchaseState = isPremium ? .purchased : .idle
        } catch {
            errorMessage = "Failed to restore: \(error.localizedDescription)"
            purchaseState = .failed(errorMessage ?? "Unknown error")
        }
    }

    func resetState() {
        purchaseState = .idle
        errorMessage = nil
    }
}
