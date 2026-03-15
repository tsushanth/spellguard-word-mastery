//
//  VocabViewModel.swift
//  SpellGuard
//
//  ViewModel for vocabulary quiz
//

import Foundation
import SwiftData
import Observation

// MARK: - Vocab Quiz Question
struct VocabQuestion: Identifiable {
    let id = UUID()
    let word: Word
    let questionType: VocabQuestionType
    let choices: [String]
    let correctAnswer: String

    enum VocabQuestionType {
        case definitionToWord     // "Which word means 'large'?"
        case wordToDefinition     // "What does 'elephant' mean?"
        case fillInSentence       // "The ___ is large." (choose word)
        case synonymMatch         // "Which is a synonym for 'large'?"
    }
}

// MARK: - Vocab ViewModel
@MainActor
@Observable
final class VocabViewModel {
    // MARK: - State
    var questions: [VocabQuestion] = []
    var currentIndex: Int = 0
    var score: Int = 0
    var correctCount: Int = 0
    var incorrectCount: Int = 0
    var selectedAnswer: String? = nil
    var showingFeedback: Bool = false
    var isComplete: Bool = false
    var selectedGradeLevel: GradeLevel = .grade1
    var isLoading: Bool = false

    // MARK: - Computed
    var currentQuestion: VocabQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }

    var accuracy: Int {
        let total = correctCount + incorrectCount
        guard total > 0 else { return 0 }
        return Int(Double(correctCount) / Double(total) * 100)
    }

    var isLastQuestion: Bool {
        currentIndex >= questions.count - 1
    }

    // MARK: - Load Questions
    func loadQuestions(from words: [Word]) {
        isLoading = true
        let shuffled = words.shuffled().prefix(10)
        questions = shuffled.compactMap { buildQuestion(from: $0, allWords: words) }
        currentIndex = 0
        score = 0
        correctCount = 0
        incorrectCount = 0
        selectedAnswer = nil
        showingFeedback = false
        isComplete = false
        isLoading = false
    }

    private func buildQuestion(from word: Word, allWords: [Word]) -> VocabQuestion? {
        let types: [VocabQuestion.VocabQuestionType] = [.wordToDefinition, .definitionToWord, .fillInSentence]
        let questionType = types.randomElement() ?? .wordToDefinition

        var choices: [String] = []
        let correct: String

        switch questionType {
        case .wordToDefinition:
            correct = word.definition
            let distractors = allWords.filter { $0.id != word.id }.shuffled().prefix(3).map { $0.definition }
            choices = ([correct] + distractors).shuffled()

        case .definitionToWord:
            correct = word.text
            let distractors = allWords.filter { $0.id != word.id }.shuffled().prefix(3).map { $0.text }
            choices = ([correct] + distractors).shuffled()

        case .fillInSentence:
            correct = word.text
            let distractors = allWords.filter { $0.id != word.id }.shuffled().prefix(3).map { $0.text }
            choices = ([correct] + distractors).shuffled()

        case .synonymMatch:
            guard !word.synonyms.isEmpty else { return nil }
            correct = word.synonyms.first!
            let distractors = allWords.filter { $0.id != word.id }.flatMap { $0.synonyms }.shuffled().prefix(3)
            choices = ([correct] + Array(distractors)).shuffled()
        }

        return VocabQuestion(word: word, questionType: questionType, choices: choices, correctAnswer: correct)
    }

    // MARK: - Select Answer
    func selectAnswer(_ answer: String) {
        guard selectedAnswer == nil, !showingFeedback else { return }
        selectedAnswer = answer

        let isCorrect = answer == currentQuestion?.correctAnswer
        if isCorrect {
            correctCount += 1
            score += 100
            HapticManager.success()
        } else {
            incorrectCount += 1
            HapticManager.error()
        }

        showingFeedback = true
    }

    // MARK: - Next Question
    func nextQuestion() {
        if isLastQuestion {
            isComplete = true
        } else {
            currentIndex += 1
            selectedAnswer = nil
            showingFeedback = false
        }
    }

    // MARK: - Reset
    func reset() {
        questions = []
        currentIndex = 0
        score = 0
        correctCount = 0
        incorrectCount = 0
        selectedAnswer = nil
        showingFeedback = false
        isComplete = false
    }
}
