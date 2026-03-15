//
//  HomeView.swift
//  SpellGuard
//
//  Main home screen
//

import SwiftUI
import SwiftData

// MARK: - Home View
struct HomeView: View {
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var modelContext
    @Query private var words: [Word]
    @Query private var sessions: [GameSession]

    @State private var showingSpellingBee = false
    @State private var showingVocabQuiz = false
    @State private var showingDailyWord = false
    @State private var showingProgress = false
    @State private var showingLeaderboard = false
    @State private var showingPaywall = false
    @State private var showingSettings = false

    private var streak: Int {
        UserDefaults.standard.integer(forKey: "spellguard.streak")
    }

    private var completedToday: Bool {
        guard let last = UserDefaults.standard.object(forKey: "spellguard.lastPracticeDate") as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(last)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Daily Challenge Banner
                    dailyChallengeBanner

                    // Stats Row
                    statsRow

                    // Game Modes
                    Text("Practice Modes")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    gameModeGrid

                    // Grade Levels
                    gradeLevelsSection

                    Spacer(minLength: 32)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSpellingBee) {
            SpellingBeeView()
        }
        .sheet(isPresented: $showingVocabQuiz) {
            VocabQuizView()
        }
        .sheet(isPresented: $showingDailyWord) {
            DailyWordView()
        }
        .sheet(isPresented: $showingProgress) {
            SpellGuardProgressView()
        }
        .sheet(isPresented: $showingLeaderboard) {
            LeaderboardView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SpellGuard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Word Mastery")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Premium badge
            if premiumManager.isPremium {
                Label("Premium", systemImage: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    Label("Go Premium", systemImage: "crown")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Daily Challenge Banner
    private var dailyChallengeBanner: some View {
        Button {
            showingDailyWord = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Daily Challenge", systemImage: "calendar.badge.plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(completedToday ? "Completed today! ✓" : "Ready for today's words?")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                if !completedToday {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .indigo],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(streak)",
                label: "Day Streak",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                value: "\(words.filter { $0.isFavorite }.count)",
                label: "Favorites",
                icon: "heart.fill",
                color: .pink
            )
            StatCard(
                value: "\(sessions.count)",
                label: "Sessions",
                icon: "checkmark.seal.fill",
                color: .green
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Game Mode Grid
    private var gameModeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            GameModeCard(
                title: "Spelling Bee",
                subtitle: "Type the spelling",
                icon: "🐝",
                color: .yellow
            ) {
                showingSpellingBee = true
            }

            GameModeCard(
                title: "Vocab Quiz",
                subtitle: "Test your knowledge",
                icon: "📚",
                color: .blue
            ) {
                showingVocabQuiz = true
            }

            GameModeCard(
                title: "My Progress",
                subtitle: "Track learning",
                icon: "📊",
                color: .green
            ) {
                showingProgress = true
            }

            GameModeCard(
                title: "Leaderboard",
                subtitle: "Compete globally",
                icon: "🏆",
                color: .purple
            ) {
                showingLeaderboard = true
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Grade Levels
    private var gradeLevelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Grade Levels")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(GradeLevel.allCases) { grade in
                        GradeLevelChip(
                            grade: grade,
                            isLocked: !premiumManager.hasAccessToGradeLevel(grade)
                        ) {
                            if premiumManager.hasAccessToGradeLevel(grade) {
                                showingSpellingBee = true
                            } else {
                                showingPaywall = true
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Game Mode Card
struct GameModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(icon)
                    .font(.largeTitle)
                Spacer()
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .frame(height: 110)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grade Level Chip
struct GradeLevelChip: View {
    let grade: GradeLevel
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                }
                Text(grade.shortName)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isLocked ? .secondary : grade.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isLocked ? Color(.systemGray6) : grade.color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isLocked ? Color(.systemGray4) : grade.color.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
