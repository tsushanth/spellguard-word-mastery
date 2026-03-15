//
//  PaywallView.swift
//  SpellGuard
//
//  Premium paywall / subscription screen
//

import SwiftUI
import StoreKit

// MARK: - Paywall View
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumManager.self) private var premiumManager

    @State private var storeKitManager = StoreKitManager()
    @State private var selectedProduct: Product? = nil
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Features
                    featuresSection

                    // Products
                    if storeKitManager.isLoading {
                        ProgressView("Loading...")
                            .padding()
                    } else {
                        productsSection
                    }

                    // Purchase button
                    purchaseButton

                    // Footer
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
            // Icon
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
            ForEach(storeKitManager.subscriptions) { product in
                ProductCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    onSelect: { selectedProduct = product }
                )
            }

            // Lifetime option
            ForEach(storeKitManager.nonConsumables) { product in
                ProductCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    onSelect: { selectedProduct = product }
                )
            }
        }
        .padding(.horizontal)
        .onAppear {
            // Auto-select yearly (best value)
            if selectedProduct == nil {
                selectedProduct = storeKitManager.subscriptions.first {
                    $0.subscription?.subscriptionPeriod.unit == .year
                } ?? storeKitManager.subscriptions.last
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

            if let product = selectedProduct,
               let subscription = product.subscription {
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
                Task { await storeKitManager.restorePurchases() }
            }
            .font(.caption)
            .foregroundStyle(.blue)

            Text("·").foregroundStyle(.secondary)

            Button("Terms") {
                // Open terms URL
            }
            .font(.caption)
            .foregroundStyle(.blue)

            Text("·").foregroundStyle(.secondary)

            Button("Privacy") {
                // Open privacy URL
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
        .padding(.bottom)
    }

    // MARK: - Purchase
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        do {
            _ = try await storeKitManager.purchase(product)
            await premiumManager.refreshPremiumStatus()
            AnalyticsService.shared.track(.subscriptionStarted(product.id))
            dismiss()
        } catch StoreKitError.userCancelled {
            // silently ignore
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
            AnalyticsService.shared.track(.subscriptionFailed(error.localizedDescription))
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
                        if let label = product.savingsLabel {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                    Text(product.periodLabel)
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
