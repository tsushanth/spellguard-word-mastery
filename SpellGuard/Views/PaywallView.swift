//
//  PaywallView.swift
//  SpellGuard
//
//  Premium paywall using PaywallKit StoreManager
//

import SwiftUI
import StoreKit
import PaywallKit

// MARK: - Paywall View
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var storeManager = AppStoreKitManager()
    @State private var selectedProduct: Product?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection

                    if storeManager.products.isEmpty {
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
                    product: pw.product,
                    isSelected: selectedProduct?.id == pw.product.id,
                    onSelect: { selectedProduct = pw.product }
                )
            }

            ForEach(storeManager.nonConsumables, id: \.id) { pw in
                ProductCard(
                    product: pw.product,
                    isSelected: selectedProduct?.id == pw.product.id,
                    onSelect: { selectedProduct = pw.product }
                )
            }
        }
        .padding(.horizontal)
        .onAppear {
            if selectedProduct == nil {
                selectedProduct = storeManager.subscriptions.first {
                    $0.product.subscription?.subscriptionPeriod.unit == .year
                }?.product ?? storeManager.subscriptions.last?.product
            }
        }
    }

    // MARK: - Purchase Button
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                guard let product = selectedProduct else { return }
                Task { await purchaseProduct(product) }
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
            .disabled(selectedProduct == nil || isPurchasing)
            .padding(.horizontal)

            if selectedProduct?.subscription != nil {
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

            Button("Terms") {}
            .font(.caption)
            .foregroundStyle(.blue)

            Text("·").foregroundStyle(.secondary)

            Button("Privacy") {}
            .font(.caption)
            .foregroundStyle(.blue)
        }
        .padding(.bottom)
    }

    // MARK: - Purchase
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        do {
            try await storeManager.purchase(product)
            await PremiumManager.shared.refreshPremiumStatus()
            AnalyticsService.shared.track(.subscriptionStarted(product.id))
            dismiss()
        } catch {
            if storeManager.purchaseState != .cancelled {
                alertMessage = error.localizedDescription
                showingAlert = true
                AnalyticsService.shared.track(.subscriptionFailed(error.localizedDescription))
            }
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
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(product.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if product.subscription?.subscriptionPeriod.unit == .year {
                            Text("Best Value - Save 60%")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                    Text(product.subscription != nil ? product.subscription!.subscriptionPeriod.debugDescription : "One-time purchase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
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
