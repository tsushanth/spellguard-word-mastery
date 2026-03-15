//
//  VocabQuizView.swift
//  SpellGuard
//
//  Vocabulary quiz view
//

import SwiftUI
import SwiftData

// MARK: - Vocab Quiz View
struct VocabQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumManager.self) private var premiumManager
    @Query private var allWords: [Word]

    @State private var viewModel = VocabViewModel()
    @State private var showingGradePicker = true

    private var filteredWords: [Word] {
        allWords.filter { $0.gradeLevel == viewModel.selectedGradeLevel.rawValue }
    }

    var body: some View {
        NavigationStack {
            Group {
                if showingGradePicker {
                    gradePicker
                } else if viewModel.isComplete {
                    vocabResults
                } else if let question = viewModel.currentQuestion {
                    questionView(question: question)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Vocab Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Grade Picker
    private var gradePicker: some View {
        VStack(spacing: 24) {
            Image("📚")
            Text("📚")
                .font(.system(size: 60))
                .padding(.top, 30)

            Text("Vocabulary Challenge")
                .font(.title2)
                .fontWeight(.bold)

            Text("Test your knowledge of word definitions, synonyms, and usage.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                Text("Select Grade Level")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(GradeLevel.allCases) { grade in
                            GradeLevelButton(
                                grade: grade,
                                isSelected: viewModel.selectedGradeLevel == grade,
                                isLocked: !premiumManager.hasAccessToGradeLevel(grade)
                            ) {
                                if premiumManager.hasAccessToGradeLevel(grade) {
                                    viewModel.selectedGradeLevel = grade
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()

            Button {
                viewModel.loadQuestions(from: filteredWords)
                showingGradePicker = false
            } label: {
                Text("Start Quiz")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(filteredWords.isEmpty ? Color.gray : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(filteredWords.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Question View
    private func questionView(question: VocabQuestion) -> some View {
        VStack(spacing: 0) {
            // Progress
            VStack(spacing: 6) {
                HStack {
                    Text("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Score: \(viewModel.score)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal)

                ProgressView(value: viewModel.progress)
                    .tint(.blue)
                    .padding(.horizontal)
            }
            .padding(.top)

            ScrollView {
                VStack(spacing: 20) {
                    // Question prompt
                    VStack(spacing: 8) {
                        Text(questionPrompt(for: question))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if question.questionType == .fillInSentence {
                            Text(question.word.exampleSentence.replacingOccurrences(of: question.word.text, with: "_____"))
                                .font(.body)
                                .italic()
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Choices
                    VStack(spacing: 10) {
                        ForEach(question.choices, id: \.self) { choice in
                            VocabChoiceButton(
                                text: choice,
                                state: choiceState(choice: choice, question: question),
                                action: {
                                    if !viewModel.showingFeedback {
                                        viewModel.selectAnswer(choice)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Feedback
                    if viewModel.showingFeedback {
                        VStack(spacing: 8) {
                            if viewModel.selectedAnswer == question.correctAnswer {
                                Label("Correct!", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.headline)
                            } else {
                                VStack(spacing: 4) {
                                    Label("Incorrect", systemImage: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.headline)
                                    Text("Correct: \(question.correctAnswer)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            (viewModel.selectedAnswer == question.correctAnswer ? Color.green : Color.red)
                                .opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            if viewModel.showingFeedback {
                Button {
                    viewModel.nextQuestion()
                } label: {
                    Text(viewModel.isLastQuestion ? "See Results" : "Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
            }
        }
    }

    // MARK: - Results
    private var vocabResults: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(viewModel.accuracy >= 80 ? "🌟" : viewModel.accuracy >= 60 ? "👍" : "📖")
                .font(.system(size: 70))

            Text(viewModel.accuracy >= 80 ? "Great Vocabulary!" : "Keep Learning!")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ResultStatCell(value: "\(viewModel.score)", label: "Score", color: .blue)
                ResultStatCell(value: "\(viewModel.accuracy)%", label: "Accuracy", color: .green)
                ResultStatCell(value: "\(viewModel.correctCount)", label: "Correct", color: .teal)
                ResultStatCell(value: "\(viewModel.incorrectCount)", label: "Incorrect", color: .red)
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.loadQuestions(from: filteredWords)
                } label: {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button { dismiss() } label: {
                    Text("Done")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Helpers
    private func questionPrompt(for question: VocabQuestion) -> String {
        switch question.questionType {
        case .wordToDefinition:
            return "What does '\(question.word.text)' mean?"
        case .definitionToWord:
            return "Which word means:\n'\(question.word.definition)'"
        case .fillInSentence:
            return "Fill in the blank:"
        case .synonymMatch:
            return "Which word is a synonym for '\(question.word.text)'?"
        }
    }

    private func choiceState(choice: String, question: VocabQuestion) -> VocabChoiceButton.ChoiceState {
        guard viewModel.showingFeedback else { return .idle }
        if choice == question.correctAnswer { return .correct }
        if choice == viewModel.selectedAnswer { return .incorrect }
        return .idle
    }
}

// MARK: - Vocab Choice Button
struct VocabChoiceButton: View {
    enum ChoiceState { case idle, correct, incorrect }

    let text: String
    let state: ChoiceState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .foregroundStyle(foregroundColor)
                    .multilineTextAlignment(.leading)
                Spacer()
                if state == .correct {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                } else if state == .incorrect {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                }
            }
            .padding()
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch state {
        case .idle: return Color(.secondarySystemGroupedBackground)
        case .correct: return Color.green.opacity(0.12)
        case .incorrect: return Color.red.opacity(0.12)
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .idle: return .primary
        case .correct: return .green
        case .incorrect: return .red
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle: return Color(.systemGray4)
        case .correct: return Color.green
        case .incorrect: return Color.red
        }
    }
}
