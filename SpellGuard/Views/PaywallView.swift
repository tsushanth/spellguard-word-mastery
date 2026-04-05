//
//  PaywallView.swift
//  SpellGuard
//
//  Premium paywall using PaywallKit
//

import SwiftUI
import PaywallKit

// MARK: - Paywall View
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeManager = AppStoreKitManager()
    @State private var selectedProductId: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isPurchasing = false

    private var allProducts: [PaywallProduct] {
        storeManager.subscriptions + storeManager.nonConsumables
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection

                    if allProducts.isEmpty {
                        ProgressView("Loading...")
                            .padding()
                    } else {
                        productsSection
                    }

                    purchaseButton
                    footerLinks
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            AnalyticsService.shared.track(.paywallViewed)
        }
        .alert("Purchase", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
            }

            Text("SpellGuard Premium")
                .font(.title2)
                .fontWeight(.bold)

            Text("Unlock all grade levels, SAT/ACT prep, and advanced features")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(premiumFeatures, id: \.title) { feature in
                FeatureRow(feature: feature)
                if feature.title != premiumFeatures.last?.title {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Products
    private var productsSection: some View {
        VStack(spacing: 10) {
            ForEach(storeManager.subscriptions, id: \.id) { pw in
                ProductCard(
                    paywallProduct: pw,
                    isSelected: selectedProductId == pw.id,
                    onSelect: { selectedProductId = pw.id }
                )
            }

            ForEach(storeManager.nonConsumables, id: \.id) { pw in
                ProductCard(
                    paywallProduct: pw,
                    isSelected: selectedProductId == pw.id,
                    onSelect: { selectedProductId = pw.id }
                )
            }
        }
        .padding(.horizontal)
        .onAppear {
            if selectedProductId == nil {
                selectedProductId = storeManager.subscriptions.first { $0.period == .yearly }?.id
                    ?? storeManager.subscriptions.last?.id
            }
        }
    }

    // MARK: - Purchase Button
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                guard let productId = selectedProductId else { return }
                Task { await purchaseProduct(productId) }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Start Premium")
                            .fontWeight(.semibold)
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedProductId == nil || isPurchasing)
            .padding(.horizontal)

            if let id = selectedProductId,
               let product = allProducts.first(where: { $0.id == id }),
               product.period != .lifetime {
                Text("Auto-renews. Cancel anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Footer Links
    private var footerLinks: some View {
        HStack(spacing: 20) {
            Button("Restore Purchases") {
                Task { await storeManager.restorePurchases() }
            }
            .font(.caption)
            .foregroundStyle(.blue)

            Text("·").foregroundStyle(.secondary)

            Link("Terms", destination: URL(string: "https://kreativekoala.llc/terms")!)
                .font(.caption)

            Text("·").foregroundStyle(.secondary)

            Link("Privacy", destination: URL(string: "https://kreativekoala.llc/privacy")!)
                .font(.caption)
        }
        .padding(.bottom)
    }

    // MARK: - Purchase
    private func purchaseProduct(_ productId: String) async {
        isPurchasing = true
        await storeManager.purchase(productId)
        switch storeManager.purchaseState {
        case .purchased:
            await PremiumManager.shared.refreshPremiumStatus()
            AnalyticsService.shared.track(.subscriptionStarted(productId))
            dismiss()
        case .failed(let msg):
            alertMessage = msg
            showingAlert = true
            AnalyticsService.shared.track(.subscriptionFailed(msg))
        case .cancelled:
            break
        default:
            break
        }
        isPurchasing = false
    }

    // MARK: - Features Data
    private var premiumFeatures: [PremiumFeature] {
        [
            PremiumFeature(icon: "graduationcap.fill", color: .blue, title: "All Grade Levels", detail: "K through 12th grade + SAT/ACT"),
            PremiumFeature(icon: "waveform", color: .purple, title: "Audio Challenge Mode", detail: "Advanced listening exercises"),
            PremiumFeature(icon: "wifi.slash", color: .green, title: "Offline Mode", detail: "Practice without internet"),
            PremiumFeature(icon: "nosign", color: .red, title: "No Ads", detail: "Distraction-free learning"),
            PremiumFeature(icon: "chart.bar.fill", color: .orange, title: "Advanced Analytics", detail: "Detailed progress insights"),
            PremiumFeature(icon: "sparkles", color: .yellow, title: "Unlimited Practice", detail: "No daily limits")
        ]
    }
}

// MARK: - Premium Feature
struct PremiumFeature {
    let icon: String
    let color: Color
    let title: String
    let detail: String
}

// MARK: - Feature Row
struct FeatureRow: View {
    let feature: PremiumFeature

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: feature.icon)
                .foregroundStyle(feature.color)
                .frame(width: 32)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(feature.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundStyle(.green)
                .fontWeight(.semibold)
        }
        .padding()
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let paywallProduct: PaywallProduct
    let isSelected: Bool
    let onSelect: () -> Void

    private var periodLabel: String {
        switch paywallProduct.period {
        case .weekly: return "per week"
        case .monthly: return "per month"
        case .yearly: return "per year"
        case .lifetime: return "One-time purchase"
        }
    }

    private var displayName: String {
        switch paywallProduct.period {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if paywallProduct.period == .yearly {
                            Text("Best Value - Save 60%")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                    Text(periodLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(paywallProduct.localizedPrice)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? .blue : .primary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.08) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
