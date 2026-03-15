//
//  SpellingBeeView.swift
//  SpellGuard
//
//  Spelling bee practice view
//

import SwiftUI
import SwiftData

// MARK: - Spelling Bee View
struct SpellingBeeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(\.modelContext) private var modelContext
    @Query private var allWords: [Word]

    @State private var viewModel = SpellingViewModel()
    @State private var showingModeSelector = true
    @State private var showingPaywall = false

    private var filteredWords: [Word] {
        allWords.filter { $0.gradeLevel == viewModel.selectedGradeLevel.rawValue }.shuffled()
    }

    var body: some View {
        NavigationStack {
            Group {
                if showingModeSelector {
                    modeSelectorView
                } else if viewModel.isComplete || viewModel.showingResults {
                    ResultsView(viewModel: viewModel, onRestart: {
                        viewModel.resetGame()
                        showingModeSelector = true
                    }, onDismiss: {
                        dismiss()
                    })
                } else if viewModel.currentQuestion != nil {
                    gameView
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Spelling Bee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    // MARK: - Mode Selector
    private var modeSelectorView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "b.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)
                    .padding(.top, 20)

                Text("Choose Your Challenge")
                    .font(.title2)
                    .fontWeight(.bold)

                // Grade Level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Grade Level")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(GradeLevel.allCases) { grade in
                                GradeLevelButton(
                                    grade: grade,
                                    isSelected: viewModel.selectedGradeLevel == grade,
                                    isLocked: !premiumManager.hasAccessToGradeLevel(grade)
                                ) {
                                    if premiumManager.hasAccessToGradeLevel(grade) {
                                        viewModel.selectedGradeLevel = grade
                                    } else {
                                        showingPaywall = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Game Mode
                VStack(alignment: .leading, spacing: 12) {
                    Text("Game Mode")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(GameMode.allCases, id: \.self) { mode in
                            GameModeRow(
                                mode: mode,
                                isSelected: viewModel.selectedGameMode == mode,
                                isLocked: mode != .typeIt && mode != .multipleChoice && !premiumManager.isPremium
                            ) {
                                if !premiumManager.isPremium && mode == .audioChallenge {
                                    showingPaywall = true
                                } else {
                                    viewModel.selectedGameMode = mode
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Button {
                    let words = Array(filteredWords.prefix(10))
                    viewModel.startGame(words: words, allWords: allWords)
                    showingModeSelector = false
                } label: {
                    Text("Start Practice")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .disabled(filteredWords.isEmpty)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Game View
    private var gameView: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressBarView(progress: viewModel.progress, streak: viewModel.streak)

            Spacer()

            // Question
            if let question = viewModel.currentQuestion {
                QuestionView(
                    question: question,
                    typedAnswer: $viewModel.typedAnswer,
                    showingFeedback: viewModel.showingFeedback,
                    lastAnswerCorrect: viewModel.lastAnswerCorrect,
                    onSpeak: { viewModel.speakWord() },
                    onSlowSpeak: { viewModel.speakSlow() },
                    onSubmit: { viewModel.submitAnswer() },
                    onSelectChoice: { viewModel.selectChoice($0) }
                )
            }

            Spacer()

            // Bottom action
            if viewModel.showingFeedback {
                Button {
                    if viewModel.isLastQuestion {
                        viewModel.finishAndShowResults()
                    } else {
                        viewModel.goToNext()
                    }
                } label: {
                    Text(viewModel.isLastQuestion ? "See Results" : "Next Word")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.lastAnswerCorrect == true ? Color.green : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Progress Bar View
struct ProgressBarView: View {
    let progress: Double
    let streak: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if streak > 0 {
                    Label("\(streak)", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
        }
        .padding(.top)
    }
}

// MARK: - Question View
struct QuestionView: View {
    let question: ChallengeQuestion
    @Binding var typedAnswer: String
    let showingFeedback: Bool
    let lastAnswerCorrect: Bool?
    let onSpeak: () -> Void
    let onSlowSpeak: () -> Void
    let onSubmit: () -> Void
    let onSelectChoice: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Word info card
            VStack(spacing: 12) {
                // Part of speech
                Text(question.word.partOfSpeech)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())

                // Definition or audio prompt
                if question.gameMode == .audioChallenge {
                    VStack(spacing: 8) {
                        Button(action: onSpeak) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.blue)
                        }
                        Text("Listen and spell the word")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(question.word.definition)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.horizontal)
                }

                // Example sentence
                if !question.word.exampleSentence.isEmpty && question.gameMode != .audioChallenge {
                    Text("\"\(question.word.exampleSentence)\"")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Audio controls
                HStack(spacing: 12) {
                    if question.gameMode != .audioChallenge {
                        Button(action: onSpeak) {
                            Label("Hear Word", systemImage: "speaker.wave.2")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)

                        Button(action: onSlowSpeak) {
                            Label("Slow", systemImage: "tortoise")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button(action: onSpeak) {
                            Label("Replay", systemImage: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            // Answer input
            if showingFeedback {
                feedbackView
            } else {
                answerInputView
            }
        }
    }

    private var feedbackView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: lastAnswerCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(lastAnswerCorrect == true ? .green : .red)
                    .font(.title)
                Text(lastAnswerCorrect == true ? "Correct!" : "Not quite...")
                    .font(.headline)
                    .foregroundStyle(lastAnswerCorrect == true ? .green : .red)
            }

            if lastAnswerCorrect == false {
                Text("Correct spelling: \(question.word.text)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(
            (lastAnswerCorrect == true ? Color.green : Color.red).opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var answerInputView: some View {
        Group {
            if question.gameMode == .multipleChoice {
                VStack(spacing: 10) {
                    Text("Choose the correct spelling:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(question.choices, id: \.self) { choice in
                        Button {
                            onSelectChoice(choice)
                        } label: {
                            Text(choice)
                                .font(.body)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            } else {
                // Type it
                VStack(spacing: 12) {
                    TextField("Type the spelling...", text: $typedAnswer)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .onSubmit { onSubmit() }

                    Button(action: onSubmit) {
                        Text("Submit")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(typedAnswer.isEmpty ? Color.gray : Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .disabled(typedAnswer.isEmpty)
                }
            }
        }
    }
}

// MARK: - Grade Level Button
struct GradeLevelButton: View {
    let grade: GradeLevel
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                }
                Text(grade.shortName)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? .white : (isLocked ? .secondary : grade.color))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? grade.color : (isLocked ? Color(.systemGray6) : grade.color.opacity(0.15)))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Game Mode Row
struct GameModeRow: View {
    let mode: GameMode
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: mode.icon)
                    .foregroundStyle(.blue)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.08) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Results View
struct ResultsView: View {
    let viewModel: SpellingViewModel
    let onRestart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Trophy or score
            VStack(spacing: 12) {
                Text(scoreEmoji)
                    .font(.system(size: 70))

                Text(scoreTitle)
                    .font(.title)
                    .fontWeight(.bold)

                if let session = viewModel.currentSession {
                    Text("Score: \(session.score)")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            // Stats grid
            if let session = viewModel.currentSession {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ResultStatCell(value: "\(session.correctCount)/\(session.totalWords)", label: "Correct", color: .green)
                    ResultStatCell(value: "\(session.accuracyPercent)%", label: "Accuracy", color: .blue)
                    ResultStatCell(value: "\(viewModel.gameEngine.maxStreak)", label: "Best Streak", color: .orange)
                    ResultStatCell(value: session.durationFormatted, label: "Time", color: .purple)
                }
                .padding(.horizontal)
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    onRestart()
                } label: {
                    Text("Practice Again")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var scoreEmoji: String {
        guard let session = viewModel.currentSession else { return "📊" }
        if session.isPerfect { return "🏆" }
        if session.accuracyPercent >= 80 { return "🌟" }
        if session.accuracyPercent >= 60 { return "👍" }
        return "📖"
    }

    private var scoreTitle: String {
        guard let session = viewModel.currentSession else { return "Complete!" }
        if session.isPerfect { return "Perfect Score!" }
        if session.accuracyPercent >= 80 { return "Excellent!" }
        if session.accuracyPercent >= 60 { return "Good Job!" }
        return "Keep Practicing!"
    }
}

// MARK: - Result Stat Cell
struct ResultStatCell: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
