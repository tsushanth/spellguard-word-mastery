//
//  OnboardingView.swift
//  SpellGuard
//
//  App onboarding flow
//

import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @Environment(AppStateManager.self) private var appState
    @State private var currentPage = 0
    @State private var selectedGrade: GradeLevel = .grade3
    @State private var notificationsEnabled = false

    private let pages = OnboardingPage.allPages

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue.opacity(0.15), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.blue : Color(.systemGray4))
                            .frame(width: index == currentPage ? 20 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.vertical, 12)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Page View
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Text(page.emoji)
                .font(.system(size: 80))

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Grade selector on last page
            if page.type == .gradeSetup {
                gradeSelector
            }

            Spacer()
        }
    }

    // MARK: - Grade Selector
    private var gradeSelector: some View {
        VStack(spacing: 12) {
            Text("Choose your grade level")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GradeLevel.allCases.prefix(6)) { grade in
                        GradeLevelButton(
                            grade: grade,
                            isSelected: selectedGrade == grade,
                            isLocked: false
                        ) {
                            selectedGrade = grade
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(selectedGrade.rawValue, forKey: "spellguard.defaultGrade")
        appState.completeOnboarding()
        AnalyticsService.shared.track(.onboardingCompleted)
    }
}

// MARK: - Onboarding Page
struct OnboardingPage {
    let emoji: String
    let title: String
    let description: String
    let type: PageType

    enum PageType { case intro, features, practice, gradeSetup }

    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "🐝",
            title: "Welcome to SpellGuard",
            description: "Master spelling and vocabulary with fun, interactive challenges designed for every grade level.",
            type: .intro
        ),
        OnboardingPage(
            emoji: "🔊",
            title: "Hear Every Word",
            description: "Listen to authentic pronunciation, then practice spelling. Perfect your ear and your pen.",
            type: .features
        ),
        OnboardingPage(
            emoji: "📊",
            title: "Track Your Progress",
            description: "Smart spaced repetition focuses on your weak spots. Watch your mastery grow over time.",
            type: .practice
        ),
        OnboardingPage(
            emoji: "🎓",
            title: "Choose Your Level",
            description: "From kindergarten basics to SAT vocabulary, we've got you covered.",
            type: .gradeSetup
        )
    ]
}
