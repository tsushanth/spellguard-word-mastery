//
//  LeaderboardViewModel.swift
//  SpellGuard
//
//  ViewModel for leaderboard
//

import Foundation
import SwiftData
import Observation

// MARK: - Leaderboard ViewModel
@MainActor
@Observable
final class LeaderboardViewModel {
    // MARK: - State
    var entries: [LeaderboardEntry] = []
    var userEntry: LeaderboardEntry? = nil
    var selectedGradeLevel: GradeLevel = .grade3
    var selectedPeriod: LeaderboardPeriod = .allTime
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Load
    func loadLeaderboard(modelContext: ModelContext) {
        isLoading = true

        // Load from SwiftData
        let descriptor = FetchDescriptor<LeaderboardEntry>(
            sortBy: [SortDescriptor(\.score, order: .reverse)]
        )
        var fetched = (try? modelContext.fetch(descriptor)) ?? []

        // If no entries, seed mock data
        if fetched.isEmpty {
            seedMockLeaderboard(modelContext: modelContext)
            fetched = (try? modelContext.fetch(descriptor)) ?? []
        }

        // Assign ranks
        for (index, entry) in fetched.enumerated() {
            entry.rank = index + 1
        }

        entries = Array(fetched.prefix(100))
        isLoading = false
    }

    // MARK: - Submit Score
    func submitScore(username: String, score: Int, gradeLevel: GradeLevel, modelContext: ModelContext) {
        let entry = LeaderboardEntry(
            username: username,
            score: score,
            gradeLevel: gradeLevel,
            streak: UserDefaults.standard.integer(forKey: "spellguard.streak")
        )
        modelContext.insert(entry)
        try? modelContext.save()
        loadLeaderboard(modelContext: modelContext)
    }

    // MARK: - User Rank
    var userRank: Int? {
        userEntry?.rank
    }

    var topEntries: [LeaderboardEntry] {
        Array(entries.prefix(10))
    }

    // MARK: - Mock Data
    private func seedMockLeaderboard(modelContext: ModelContext) {
        let mockUsers: [(String, Int, String)] = [
            ("SpellChamp", 9800, "🏆"),
            ("WordWizard", 9450, "🧙"),
            ("LexiMaster", 9200, "📚"),
            ("SpellingBee", 8950, "🐝"),
            ("VocabKing", 8700, "👑"),
            ("LetterPro", 8500, "✍️"),
            ("GrammarGuru", 8200, "📝"),
            ("AlphaChamp", 7900, "🌟"),
            ("WordSmith", 7650, "⚒️"),
            ("SpellStar", 7400, "⭐")
        ]

        for (index, (name, score, _)) in mockUsers.enumerated() {
            let entry = LeaderboardEntry(
                username: name,
                score: score,
                gradeLevel: .grade3,
                rank: index + 1,
                streak: Int.random(in: 1...30)
            )
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}

// MARK: - Leaderboard Period
enum LeaderboardPeriod: String, CaseIterable {
    case daily = "Today"
    case weekly = "This Week"
    case allTime = "All Time"
}
