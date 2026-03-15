//
//  SpellingChallenge.swift
//  SpellGuard
//
//  Spelling challenge model
//

import Foundation
import SwiftData

// MARK: - Game Mode
enum GameMode: String, CaseIterable, Codable {
    case typeIt = "type_it"
    case multipleChoice = "multiple_choice"
    case audioChallenge = "audio_challenge"
    case fillInBlank = "fill_in_blank"

    var displayName: String {
        switch self {
        case .typeIt: return "Type It"
        case .multipleChoice: return "Multiple Choice"
        case .audioChallenge: return "Audio Challenge"
        case .fillInBlank: return "Fill in the Blank"
        }
    }

    var icon: String {
        switch self {
        case .typeIt: return "keyboard"
        case .multipleChoice: return "list.bullet"
        case .audioChallenge: return "speaker.wave.2"
        case .fillInBlank: return "pencil.line"
        }
    }

    var description: String {
        switch self {
        case .typeIt: return "Hear the word and type the spelling"
        case .multipleChoice: return "Choose the correct spelling"
        case .audioChallenge: return "Listen and identify the word"
        case .fillInBlank: return "Complete the missing letters"
        }
    }
}

// MARK: - Spelling Challenge
@Model
final class SpellingChallenge {
    var id: UUID
    var wordId: UUID
    var wordText: String
    var gameMode: String
    var isCorrect: Bool?
    var userAnswer: String
    var timeTaken: Double // seconds
    var dateCompleted: Date?
    var sessionId: UUID
    var hintsUsed: Int

    init(
        id: UUID = UUID(),
        wordId: UUID,
        wordText: String,
        gameMode: GameMode,
        sessionId: UUID
    ) {
        self.id = id
        self.wordId = wordId
        self.wordText = wordText
        self.gameMode = gameMode.rawValue
        self.isCorrect = nil
        self.userAnswer = ""
        self.timeTaken = 0
        self.dateCompleted = nil
        self.sessionId = sessionId
        self.hintsUsed = 0
    }

    var gameModeEnum: GameMode {
        GameMode(rawValue: gameMode) ?? .typeIt
    }

    func complete(answer: String, correct: Bool, timeTaken: Double) {
        self.userAnswer = answer
        self.isCorrect = correct
        self.timeTaken = timeTaken
        self.dateCompleted = Date()
    }
}

// MARK: - Challenge Question (non-persistent)
struct ChallengeQuestion: Identifiable {
    let id: UUID
    let word: Word
    let gameMode: GameMode
    var choices: [String] // For multiple choice
    var hiddenWord: String // For fill-in-blank
    var hintLetters: [Bool] // Which letters are revealed

    init(word: Word, gameMode: GameMode, allWords: [Word] = []) {
        self.id = UUID()
        self.word = word
        self.gameMode = gameMode
        self.hintLetters = Array(repeating: false, count: word.text.count)

        // Generate choices for multiple choice
        if gameMode == .multipleChoice {
            var options = [word.text]
            let distractors = allWords
                .filter { $0.id != word.id }
                .shuffled()
                .prefix(3)
                .map { $0.text }
            options.append(contentsOf: distractors)
            self.choices = options.shuffled()
        } else {
            self.choices = []
        }

        // Generate hidden word for fill-in-blank (hide ~40% of letters)
        if gameMode == .fillInBlank {
            let letters = Array(word.text)
            var hidden = letters.map { String($0) }
            let countToHide = max(1, letters.count * 2 / 5)
            var indices = Array(0..<letters.count).shuffled().prefix(countToHide)
            for i in indices {
                hidden[i] = "_"
            }
            self.hiddenWord = hidden.joined()
        } else {
            self.hiddenWord = word.text
        }
    }

    var isCorrect: ((String) -> Bool) {
        { answer in
            answer.lowercased().trimmingCharacters(in: .whitespaces) == self.word.text.lowercased()
        }
    }
}
