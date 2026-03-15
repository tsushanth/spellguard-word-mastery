//
//  GameSession.swift
//  SpellGuard
//
//  Game session model for tracking quiz sessions
//

import Foundation
import SwiftData

// MARK: - Session Type
enum SessionType: String, Codable {
    case spellingBee = "spelling_bee"
    case vocabQuiz = "vocab_quiz"
    case dailyChallenge = "daily_challenge"
    case weekReview = "weak_word_review"
    case freePlay = "free_play"

    var displayName: String {
        switch self {
        case .spellingBee: return "Spelling Bee"
        case .vocabQuiz: return "Vocab Quiz"
        case .dailyChallenge: return "Daily Challenge"
        case .weekReview: return "Weak Word Review"
        case .freePlay: return "Free Play"
        }
    }
}

// MARK: - Game Session Model
@Model
final class GameSession {
    var id: UUID
    var sessionType: String
    var gradeLevel: String
    var gameMode: String
    var startDate: Date
    var endDate: Date?
    var correctCount: Int
    var incorrectCount: Int
    var totalWords: Int
    var score: Int
    var streakBonus: Int
    var timeBonus: Int
    var isPerfect: Bool
    var wordIds: [UUID]

    init(
        id: UUID = UUID(),
        sessionType: SessionType,
        gradeLevel: GradeLevel,
        gameMode: GameMode,
        totalWords: Int = 10
    ) {
        self.id = id
        self.sessionType = sessionType.rawValue
        self.gradeLevel = gradeLevel.rawValue
        self.gameMode = gameMode.rawValue
        self.startDate = Date()
        self.endDate = nil
        self.correctCount = 0
        self.incorrectCount = 0
        self.totalWords = totalWords
        self.score = 0
        self.streakBonus = 0
        self.timeBonus = 0
        self.isPerfect = false
        self.wordIds = []
    }

    var sessionTypeEnum: SessionType {
        SessionType(rawValue: sessionType) ?? .freePlay
    }

    var gradeLevelEnum: GradeLevel {
        GradeLevel(rawValue: gradeLevel) ?? .grade1
    }

    var gameModeEnum: GameMode {
        GameMode(rawValue: gameMode) ?? .typeIt
    }

    var accuracy: Double {
        let total = correctCount + incorrectCount
        guard total > 0 else { return 0 }
        return Double(correctCount) / Double(total)
    }

    var accuracyPercent: Int {
        Int(accuracy * 100)
    }

    var duration: TimeInterval {
        guard let end = endDate else { return 0 }
        return end.timeIntervalSince(startDate)
    }

    var durationFormatted: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    func complete() {
        endDate = Date()
        isPerfect = incorrectCount == 0 && correctCount == totalWords

        // Calculate final score
        let baseScore = correctCount * 100
        let accuracyBonus = isPerfect ? 500 : 0
        score = baseScore + streakBonus + timeBonus + accuracyBonus
    }

    func recordAnswer(correct: Bool, wordId: UUID, currentStreak: Int, timeTaken: Double) {
        if correct {
            correctCount += 1
            // Streak bonus: +10 per streak above 3
            if currentStreak > 3 {
                streakBonus += (currentStreak - 3) * 10
            }
            // Time bonus: faster = more points (max 50)
            if timeTaken < 5 {
                timeBonus += 50
            } else if timeTaken < 10 {
                timeBonus += 30
            } else if timeTaken < 20 {
                timeBonus += 10
            }
        } else {
            incorrectCount += 1
        }
        wordIds.append(wordId)
    }
}

// MARK: - Daily Challenge
@Model
final class DailyChallenge {
    var id: UUID
    var date: Date
    var gradeLevel: String
    var wordIds: [UUID]
    var isCompleted: Bool
    var score: Int
    var sessionId: UUID?

    init(date: Date = Date(), gradeLevel: GradeLevel = .grade3, wordIds: [UUID] = []) {
        self.id = UUID()
        self.date = date
        self.gradeLevel = gradeLevel.rawValue
        self.wordIds = wordIds
        self.isCompleted = false
        self.score = 0
        self.sessionId = nil
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Leaderboard Entry
@Model
final class LeaderboardEntry {
    var id: UUID
    var username: String
    var score: Int
    var gradeLevel: String
    var rank: Int
    var dateAchieved: Date
    var streak: Int
    var avatar: String

    init(
        username: String,
        score: Int,
        gradeLevel: GradeLevel,
        rank: Int = 0,
        streak: Int = 0,
        avatar: String = "person.circle"
    ) {
        self.id = UUID()
        self.username = username
        self.score = score
        self.gradeLevel = gradeLevel.rawValue
        self.rank = rank
        self.dateAchieved = Date()
        self.streak = streak
        self.avatar = avatar
    }
}
