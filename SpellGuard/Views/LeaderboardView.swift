//
//  LeaderboardView.swift
//  SpellGuard
//
//  Leaderboard view
//

import SwiftUI
import SwiftData

// MARK: - Leaderboard View
struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = LeaderboardViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Period picker
                Picker("Period", selection: $viewModel.selectedPeriod) {
                    ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if viewModel.entries.isEmpty {
                    ContentUnavailableView(
                        "No Scores Yet",
                        systemImage: "trophy",
                        description: Text("Complete spelling challenges to see your scores here.")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Top 3 podium
                            if viewModel.entries.count >= 3 {
                                podiumView
                            }

                            // Full list
                            ForEach(viewModel.entries.dropFirst(min(3, viewModel.entries.count)).prefix(20)) { entry in
                                LeaderboardRowView(entry: entry)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            viewModel.loadLeaderboard(modelContext: modelContext)
        }
    }

    // MARK: - Podium
    private var podiumView: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // 2nd place
            if viewModel.entries.count >= 2 {
                PodiumCell(entry: viewModel.entries[1], rank: 2, height: 90)
            }
            // 1st place
            PodiumCell(entry: viewModel.entries[0], rank: 1, height: 110)
            // 3rd place
            if viewModel.entries.count >= 3 {
                PodiumCell(entry: viewModel.entries[2], rank: 3, height: 75)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Podium Cell
struct PodiumCell: View {
    let entry: LeaderboardEntry
    let rank: Int
    let height: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            Text(rankEmoji)
                .font(.title2)

            Text(entry.username)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("\(entry.score)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(rankColor)

            Rectangle()
                .fill(rankColor.opacity(0.3))
                .frame(height: height)
                .overlay(
                    Text("#\(rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(rankColor)
                        .padding(.bottom, 8),
                    alignment: .bottom
                )
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 8,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 8
                    )
                )
        }
        .frame(maxWidth: .infinity)
    }

    private var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "🏅"
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .blue
        }
    }
}

// MARK: - Leaderboard Row View
struct LeaderboardRowView: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack {
            // Rank
            Text("#\(entry.rank)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(width: 36)

            // Avatar
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue.opacity(0.6))

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    if entry.streak > 0 {
                        Label("\(entry.streak)", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text("Grade \(entry.gradeLevel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("\(entry.score)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
