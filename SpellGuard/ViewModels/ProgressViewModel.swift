//
//  ProgressViewModel.swift
//  SpellGuard
//
//  ViewModel for progress tracking
//

import Foundation
import SwiftData
import Observation

// MARK: - Progress Stats
struct ProgressStats {
    var totalWordsLearned: Int = 0
    var totalWordsAttempted: Int = 0
    var totalCorrect: Int = 0
    var totalIncorrect: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalSessionsCompleted: Int = 0
    var totalTimeSpent: TimeInterval = 0
    var masteredWords: Int = 0
    var weakWords: Int = 0
    var favoriteWords: Int = 0
    var dailyChallengesCompleted: Int = 0
    var averageAccuracy: Double = 0.0
    var bestScore: Int = 0
    var recentActivity: [Date] = []

    var overallAccuracyPercent: Int {
        let total = totalCorrect + totalIncorrect
        guard total > 0 else { return 0 }
        return Int(Double(totalCorrect) / Double(total) * 100)
    }

    var timeSpentFormatted: String {
        let hours = Int(totalTimeSpent) / 3600
        let minutes = (Int(totalTimeSpent) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Progress ViewModel
@MainActor
@Observable
final class ProgressViewModel {
    // MARK: - State
    var stats: ProgressStats = ProgressStats()
    var wordProgressItems: [WordProgress] = []
    var weakWords: [WordProgress] = []
    var masteredWords: [WordProgress] = []
    var recentSessions: [GameSession] = []
    var gradeProgressMap: [String: Double] = [:]
    var isLoading: Bool = false
    var selectedGradeLevel: GradeLevel? = nil

    // MARK: - Load Progress
    func loadProgress(modelContext: ModelContext) {
        isLoading = true

        // Load word progress
        let progressDescriptor = FetchDescriptor<WordProgress>()
        let allProgress = (try? modelContext.fetch(progressDescriptor)) ?? []
        wordProgressItems = allProgress

        // Compute stats
        var s = ProgressStats()
        s.totalWordsAttempted = allProgress.filter { $0.correctCount + $0.incorrectCount > 0 }.count
        s.totalCorrect = allProgress.reduce(0) { $0 + $1.correctCount }
        s.totalIncorrect = allProgress.reduce(0) { $0 + $1.incorrectCount }
        s.masteredWords = allProgress.filter { $0.masteryLevel >= 5 }.count
        s.weakWords = allProgress.filter { $0.isWeak }.count
        s.totalWordsLearned = allProgress.filter { $0.masteryLevel >= 2 }.count

        // Load sessions
        let sessionDescriptor = FetchDescriptor<GameSession>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []
        recentSessions = Array(sessions.prefix(20))
        s.totalSessionsCompleted = sessions.count
        s.totalTimeSpent = sessions.reduce(0) { $0 + $1.duration }
        s.bestScore = sessions.map { $0.score }.max() ?? 0

        // Streak
        s.currentStreak = UserDefaults.standard.integer(forKey: "spellguard.streak")
        s.longestStreak = UserDefaults.standard.integer(forKey: "spellguard.longestStreak")

        // Grade progress
        for grade in GradeLevel.allCases {
            let gradeProgress = allProgress.filter { $0.gradeLevel == grade.rawValue }
            let gradeTotal = grade.wordCount
            let gradeKnown = gradeProgress.filter { $0.masteryLevel >= 2 }.count
            gradeProgressMap[grade.rawValue] = Double(gradeKnown) / Double(gradeTotal)
        }

        weakWords = allProgress.filter { $0.isWeak && $0.masteryLevel < 3 }
        masteredWords = allProgress.filter { $0.masteryLevel >= 5 }

        stats = s
        isLoading = false
    }

    // MARK: - Update Streak
    func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastPractice = UserDefaults.standard.object(forKey: "spellguard.lastPracticeDate") as? Date

        if let last = lastPractice {
            let lastDay = Calendar.current.startOfDay(for: last)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if diff == 0 {
                // Already practiced today
                return
            } else if diff == 1 {
                // Consecutive day
                var current = UserDefaults.standard.integer(forKey: "spellguard.streak")
                current += 1
                UserDefaults.standard.set(current, forKey: "spellguard.streak")

                let longest = UserDefaults.standard.integer(forKey: "spellguard.longestStreak")
                if current > longest {
                    UserDefaults.standard.set(current, forKey: "spellguard.longestStreak")
                }

                AnalyticsService.shared.track(.streakUpdated(current))
            } else {
                // Streak broken
                UserDefaults.standard.set(1, forKey: "spellguard.streak")
            }
        } else {
            UserDefaults.standard.set(1, forKey: "spellguard.streak")
        }

        UserDefaults.standard.set(Date(), forKey: "spellguard.lastPracticeDate")
    }

    // MARK: - Save Session Progress
    func saveSessionProgress(session: GameSession, words: [Word], modelContext: ModelContext) {
        for wordId in session.wordIds {
            guard let word = words.first(where: { $0.id == wordId }) else { continue }

            // Find or create progress
            let descriptor = FetchDescriptor<WordProgress>()
            let allProgress = (try? modelContext.fetch(descriptor)) ?? []

            if let existing = allProgress.first(where: { $0.wordId == wordId }) {
                let isCorrect = session.correctCount > session.incorrectCount // simplified
                existing.recordAttempt(correct: isCorrect)
            } else {
                let newProgress = WordProgress(wordId: wordId, wordText: word.text, gradeLevel: word.gradeLevel)
                modelContext.insert(newProgress)
            }
        }

        try? modelContext.save()
        updateStreak()
    }

    // MARK: - Grade Progress
    func progressForGrade(_ grade: GradeLevel) -> Double {
        gradeProgressMap[grade.rawValue] ?? 0
    }
}
