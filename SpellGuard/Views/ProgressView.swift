//
//  ProgressView.swift
//  SpellGuard
//
//  Progress tracking view
//

import SwiftUI
import SwiftData

// MARK: - Progress View (renamed to avoid conflict with SwiftUI.ProgressView)
struct SpellGuardProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [GameSession]
    @Query private var wordProgress: [WordProgress]

    @State private var viewModel = ProgressViewModel()
    @State private var selectedTab: ProgressTab = .overview

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Tab", selection: $selectedTab) {
                    ForEach(ProgressTab.allCases, id: \.self) { tab in
                        Text(tab.displayName).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    switch selectedTab {
                    case .overview: overviewSection
                    case .grades: gradeSection
                    case .weakWords: weakWordsSection
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            viewModel.loadProgress(modelContext: modelContext)
        }
    }

    // MARK: - Overview
    private var overviewSection: some View {
        VStack(spacing: 16) {
            // Streak card
            streakCard

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ProgressStatCard(
                    value: "\(viewModel.stats.totalWordsLearned)",
                    label: "Words Learned",
                    icon: "book.fill",
                    color: .blue
                )
                ProgressStatCard(
                    value: "\(viewModel.stats.masteredWords)",
                    label: "Mastered",
                    icon: "star.fill",
                    color: .yellow
                )
                ProgressStatCard(
                    value: "\(viewModel.stats.overallAccuracyPercent)%",
                    label: "Accuracy",
                    icon: "target",
                    color: .green
                )
                ProgressStatCard(
                    value: "\(viewModel.stats.totalSessionsCompleted)",
                    label: "Sessions",
                    icon: "checkmark.seal.fill",
                    color: .purple
                )
                ProgressStatCard(
                    value: viewModel.stats.timeSpentFormatted,
                    label: "Time Spent",
                    icon: "clock.fill",
                    color: .orange
                )
                ProgressStatCard(
                    value: "\(viewModel.stats.bestScore)",
                    label: "Best Score",
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
            .padding(.horizontal)

            // Recent sessions
            if !viewModel.recentSessions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Sessions")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(viewModel.recentSessions.prefix(5)) { session in
                            SessionRow(session: session)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }

    // MARK: - Streak Card
    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("🔥")
                    Text("\(viewModel.stats.currentStreak) Day Streak")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Text("Longest: \(viewModel.stats.longestStreak) days")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "flame.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Grade Section
    private var gradeSection: some View {
        VStack(spacing: 12) {
            ForEach(GradeLevel.allCases) { grade in
                GradeProgressRow(
                    grade: grade,
                    progress: viewModel.progressForGrade(grade)
                )
            }
        }
        .padding()
    }

    // MARK: - Weak Words
    private var weakWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.weakWords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("No weak words!")
                        .font(.headline)
                    Text("Keep practicing to maintain your skills.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                Text("Words to Review (\(viewModel.weakWords.count))")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(viewModel.weakWords) { progress in
                    WeakWordRow(progress: progress)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Progress Tab
enum ProgressTab: CaseIterable {
    case overview, grades, weakWords

    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .grades: return "Grades"
        case .weakWords: return "Weak Words"
        }
    }
}

// MARK: - Progress Stat Card
struct ProgressStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title2)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Session Row
struct SessionRow: View {
    let session: GameSession

    var body: some View {
        HStack {
            Image(systemName: session.isPerfect ? "star.fill" : "checkmark.circle.fill")
                .foregroundStyle(session.isPerfect ? .yellow : .green)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.sessionTypeEnum.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(session.gradeLevelEnum.displayName) • \(session.accuracyPercent)% accuracy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.score)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(session.durationFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Grade Progress Row
struct GradeProgressRow: View {
    let grade: GradeLevel
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(grade.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(grade.color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(grade.color)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Weak Word Row
struct WeakWordRow: View {
    let progress: WordProgress

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(progress.wordText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(progress.accuracyPercent)% accuracy • \(progress.masteryLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Mastery dots
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i < progress.masteryLevel ? Color.orange : Color(.systemGray5))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Alias removed to avoid conflict with SwiftUI.ProgressView
