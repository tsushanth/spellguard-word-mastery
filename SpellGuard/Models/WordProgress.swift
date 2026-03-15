//
//  WordProgress.swift
//  SpellGuard
//
//  Tracks user's progress on individual words
//

import Foundation
import SwiftData

// MARK: - Word Progress Model
@Model
final class WordProgress {
    var id: UUID
    var wordId: UUID
    var wordText: String
    var correctCount: Int
    var incorrectCount: Int
    var lastPracticed: Date?
    var nextReviewDate: Date
    var masteryLevel: Int // 0-5
    var isWeak: Bool
    var streak: Int
    var gradeLevel: String

    init(
        id: UUID = UUID(),
        wordId: UUID,
        wordText: String,
        gradeLevel: String = GradeLevel.grade1.rawValue
    ) {
        self.id = id
        self.wordId = wordId
        self.wordText = wordText
        self.correctCount = 0
        self.incorrectCount = 0
        self.lastPracticed = nil
        self.nextReviewDate = Date()
        self.masteryLevel = 0
        self.isWeak = false
        self.streak = 0
        self.gradeLevel = gradeLevel
    }

    var accuracy: Double {
        let total = correctCount + incorrectCount
        guard total > 0 else { return 0 }
        return Double(correctCount) / Double(total)
    }

    var accuracyPercent: Int {
        Int(accuracy * 100)
    }

    var masteryLabel: String {
        switch masteryLevel {
        case 0: return "New"
        case 1: return "Learning"
        case 2: return "Familiar"
        case 3: return "Practiced"
        case 4: return "Proficient"
        case 5: return "Mastered"
        default: return "Unknown"
        }
    }

    func recordAttempt(correct: Bool) {
        if correct {
            correctCount += 1
            streak += 1
            if masteryLevel < 5 && streak >= 3 {
                masteryLevel = min(5, masteryLevel + 1)
                streak = 0
            }
        } else {
            incorrectCount += 1
            streak = 0
            if masteryLevel > 0 {
                masteryLevel = max(0, masteryLevel - 1)
            }
            isWeak = true
        }
        lastPracticed = Date()

        // Schedule next review using spaced repetition
        let daysUntilReview: Double
        switch masteryLevel {
        case 0: daysUntilReview = 0
        case 1: daysUntilReview = 1
        case 2: daysUntilReview = 3
        case 3: daysUntilReview = 7
        case 4: daysUntilReview = 14
        case 5: daysUntilReview = 30
        default: daysUntilReview = 1
        }

        nextReviewDate = Date().addingTimeInterval(daysUntilReview * 86400)

        // Update weak status
        if accuracy >= 0.8 && (correctCount + incorrectCount) >= 5 {
            isWeak = false
        }
    }

    var isDueForReview: Bool {
        nextReviewDate <= Date()
    }
}
