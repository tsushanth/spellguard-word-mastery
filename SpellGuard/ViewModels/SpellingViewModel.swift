//
//  SpellingViewModel.swift
//  SpellGuard
//
//  ViewModel for spelling bee game
//

import Foundation
import SwiftData
import Observation

// MARK: - Spelling ViewModel
@MainActor
@Observable
final class SpellingViewModel {
    // MARK: - Dependencies
    let gameEngine = GameEngine()
    let speechEngine = SpeechEngine.shared

    // MARK: - State
    var selectedGradeLevel: GradeLevel = .grade1
    var selectedGameMode: GameMode = .typeIt
    var typedAnswer: String = ""
    var showingResults: Bool = false
    var showingWordDetails: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Computed
    var currentQuestion: ChallengeQuestion? { gameEngine.currentQuestion }
    var currentSession: GameSession? { gameEngine.currentSession }
    var streak: Int { gameEngine.streak }
    var progress: Double { gameEngine.progress }
    var lastAnswerCorrect: Bool? { gameEngine.lastAnswerCorrect }
    var showingFeedback: Bool { gameEngine.showingFeedback }
    var isComplete: Bool { gameEngine.isComplete }
    var isLastQuestion: Bool { gameEngine.isLastQuestion }
    var isSpeaking: Bool { speechEngine.isSpeaking }

    // MARK: - Start Game
    func startGame(words: [Word], allWords: [Word]) {
        guard !words.isEmpty else {
            errorMessage = "No words available for this grade level."
            return
        }
        typedAnswer = ""
        showingResults = false
        gameEngine.startSession(
            words: words,
            gameMode: selectedGameMode,
            sessionType: .spellingBee,
            gradeLevel: selectedGradeLevel,
            allWords: allWords
        )
        AnalyticsService.shared.track(.sessionStarted(.spellingBee))
    }

    // MARK: - Submit
    func submitAnswer() {
        let answer = typedAnswer.trimmingCharacters(in: .whitespaces)
        guard !answer.isEmpty else { return }
        gameEngine.submitAnswer(answer)
        typedAnswer = ""
    }

    func selectChoice(_ choice: String) {
        gameEngine.submitAnswer(choice)
    }

    // MARK: - Next
    func goToNext() {
        if gameEngine.isLastQuestion && gameEngine.lastAnswerCorrect != nil {
            gameEngine.nextQuestion()
            showingResults = true
        } else {
            gameEngine.nextQuestion()
        }
    }

    // MARK: - Speech
    func speakWord() {
        gameEngine.repeatWord()
    }

    func speakSlow() {
        gameEngine.slowPronunciation()
    }

    // MARK: - Results
    func finishAndShowResults() {
        if let session = currentSession {
            AnalyticsService.shared.track(.sessionCompleted(
                score: session.score,
                accuracy: session.accuracyPercent
            ))
        }
        showingResults = true
    }

    // MARK: - Reset
    func resetGame() {
        gameEngine.reset()
        typedAnswer = ""
        showingResults = false
        showingWordDetails = false
    }
}
