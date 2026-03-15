//
//  GameEngine.swift
//  SpellGuard
//
//  Core game logic engine
//

import Foundation
import SwiftData
import UIKit

// MARK: - Game Engine
@MainActor
@Observable
final class GameEngine {
    // MARK: - State
    private(set) var currentQuestion: ChallengeQuestion?
    private(set) var currentSession: GameSession?
    private(set) var questions: [ChallengeQuestion] = []
    private(set) var currentIndex: Int = 0
    private(set) var streak: Int = 0
    private(set) var maxStreak: Int = 0
    private(set) var gameState: GameState = .idle
    private(set) var lastAnswerCorrect: Bool? = nil
    private(set) var showingFeedback: Bool = false
    private var questionStartTime: Date = Date()

    // MARK: - Computed
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }

    var isLastQuestion: Bool {
        currentIndex >= questions.count - 1
    }

    var isComplete: Bool {
        gameState == .complete
    }

    var questionsRemaining: Int {
        max(0, questions.count - currentIndex)
    }

    // MARK: - Start Session
    func startSession(
        words: [Word],
        gameMode: GameMode,
        sessionType: SessionType,
        gradeLevel: GradeLevel,
        allWords: [Word]
    ) {
        let session = GameSession(
            sessionType: sessionType,
            gradeLevel: gradeLevel,
            gameMode: gameMode,
            totalWords: words.count
        )
        currentSession = session

        // Build questions
        questions = words.map { ChallengeQuestion(word: $0, gameMode: gameMode, allWords: allWords) }
        currentIndex = 0
        streak = 0
        maxStreak = 0
        gameState = .playing
        lastAnswerCorrect = nil
        showingFeedback = false

        advanceToCurrentQuestion()
    }

    private func advanceToCurrentQuestion() {
        guard currentIndex < questions.count else {
            completeSession()
            return
        }
        currentQuestion = questions[currentIndex]
        questionStartTime = Date()

        // Auto-speak for audio challenge and type-it mode
        if let word = currentQuestion?.word {
            let gameMode = currentQuestion?.gameMode
            if gameMode == .audioChallenge || gameMode == .typeIt {
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
                    SpeechEngine.shared.speak(word.text)
                }
            }
        }
    }

    // MARK: - Submit Answer
    func submitAnswer(_ answer: String) {
        guard let question = currentQuestion,
              let session = currentSession,
              gameState == .playing else { return }

        let timeTaken = Date().timeIntervalSince(questionStartTime)
        let isCorrect = question.isCorrect(answer)

        lastAnswerCorrect = isCorrect
        showingFeedback = true

        // Update streak
        if isCorrect {
            streak += 1
            maxStreak = max(maxStreak, streak)
        } else {
            streak = 0
        }

        // Record in session
        session.recordAnswer(
            correct: isCorrect,
            wordId: question.word.id,
            currentStreak: streak,
            timeTaken: timeTaken
        )

        // Haptic feedback
        if isCorrect {
            HapticManager.success()
        } else {
            HapticManager.error()
        }
    }

    // MARK: - Next Question
    func nextQuestion() {
        showingFeedback = false
        lastAnswerCorrect = nil
        currentIndex += 1

        if currentIndex >= questions.count {
            completeSession()
        } else {
            advanceToCurrentQuestion()
        }
    }

    // MARK: - Complete
    private func completeSession() {
        gameState = .complete
        currentSession?.complete()
    }

    // MARK: - Repeat Word
    func repeatWord() {
        guard let word = currentQuestion?.word else { return }
        SpeechEngine.shared.speak(word.text)
    }

    // MARK: - Slow Pronunciation
    func slowPronunciation() {
        guard let word = currentQuestion?.word else { return }
        SpeechEngine.shared.speak(word.text, slow: true)
    }

    // MARK: - Reset
    func reset() {
        currentQuestion = nil
        currentSession = nil
        questions = []
        currentIndex = 0
        streak = 0
        maxStreak = 0
        gameState = .idle
        lastAnswerCorrect = nil
        showingFeedback = false
    }
}

// MARK: - Game State
enum GameState {
    case idle
    case playing
    case paused
    case complete
}

// MARK: - Haptic Manager
enum HapticManager {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
