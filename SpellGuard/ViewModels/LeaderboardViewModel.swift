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

}

// MARK: - Leaderboard Period
enum LeaderboardPeriod: String, CaseIterable {
    case daily = "Today"
    case weekly = "This Week"
    case allTime = "All Time"
}
