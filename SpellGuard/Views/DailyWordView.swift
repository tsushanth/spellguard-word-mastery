//
//  DailyWordView.swift
//  SpellGuard
//
//  Daily word challenge view
//

import SwiftUI
import SwiftData

// MARK: - Daily Word View
struct DailyWordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allWords: [Word]
    @Query(sort: \DailyChallenge.date, order: .reverse) private var dailyChallenges: [DailyChallenge]

    @State private var todaysWords: [Word] = []
    @State private var currentWordIndex: Int = 0
    @State private var isPlayingChallenge: Bool = false
    @State private var challengeCompleted: Bool = false
    @State private var score: Int = 0
    @State private var correctAnswers: Int = 0
    @State private var typedAnswer: String = ""
    @State private var showingFeedback: Bool = false
    @State private var lastAnswerCorrect: Bool? = nil

    private var todayChallenge: DailyChallenge? {
        dailyChallenges.first { Calendar.current.isDateInToday($0.date) }
    }

    private var currentWord: Word? {
        guard currentWordIndex < todaysWords.count else { return nil }
        return todaysWords[currentWordIndex]
    }

    var body: some View {
        NavigationStack {
            Group {
                if challengeCompleted {
                    completedView
                } else if isPlayingChallenge {
                    challengeView
                } else {
                    introView
                }
            }
            .navigationTitle("Daily Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear { loadTodaysWords() }
    }

    // MARK: - Intro View
    private var introView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Calendar header
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                        .padding(.top, 30)

                    Text("Daily Challenge")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Today's preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Words")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(todaysWords.prefix(5)) { word in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.blue.opacity(0.5))
                                Text(word.text.capitalized)
                                    .font(.body)
                                Spacer()
                                Text("Grade \(word.gradeLevel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        if todaysWords.count > 5 {
                            Text("+ \(todaysWords.count - 5) more words")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Past results
                if !dailyChallenges.filter({ !Calendar.current.isDateInToday($0.date) }).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Results")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 6) {
                            ForEach(dailyChallenges.filter { !Calendar.current.isDateInToday($0.date) }.prefix(5)) { challenge in
                                HStack {
                                    Image(systemName: challenge.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(challenge.isCompleted ? .green : .secondary)
                                    Text(challenge.dateString)
                                        .font(.subheadline)
                                    Spacer()
                                    if challenge.isCompleted {
                                        Text("Score: \(challenge.score)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 20)

                Button {
                    startChallenge()
                } label: {
                    HStack {
                        Image(systemName: todayChallenge?.isCompleted == true ? "arrow.clockwise" : "play.fill")
                        Text(todayChallenge?.isCompleted == true ? "Practice Again" : "Start Challenge")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    // MARK: - Challenge View
    private var challengeView: some View {
        VStack(spacing: 0) {
            // Progress header
            VStack(spacing: 8) {
                HStack {
                    Text("Word \(currentWordIndex + 1) of \(todaysWords.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("\(score)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                .padding(.horizontal)
                ProgressView(value: Double(currentWordIndex) / Double(max(todaysWords.count, 1)))
                    .tint(.blue)
                    .padding(.horizontal)
            }
            .padding(.top)

            Spacer()

            if let word = currentWord {
                VStack(spacing: 20) {
                    // Word card
                    VStack(spacing: 12) {
                        Button {
                            SpeechEngine.shared.speak(word.text)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.blue)
                        }

                        Text("Listen carefully and spell the word")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(word.definition)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Feedback
                    if showingFeedback {
                        HStack {
                            Image(systemName: lastAnswerCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(lastAnswerCorrect == true ? "Correct!" : "Answer: \(word.text)")
                        }
                        .font(.headline)
                        .foregroundStyle(lastAnswerCorrect == true ? .green : .red)
                        .padding()
                        .background((lastAnswerCorrect == true ? Color.green : Color.red).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    } else {
                        // Input
                        VStack(spacing: 12) {
                            TextField("Spell the word...", text: $typedAnswer)
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
                                .onSubmit { submitDailyAnswer() }

                            Button { submitDailyAnswer() } label: {
                                Text("Submit")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(typedAnswer.isEmpty ? Color.gray : Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(typedAnswer.isEmpty)
                            .padding(.horizontal)
                        }
                    }
                }
            }

            Spacer()

            if showingFeedback {
                Button {
                    advanceWord()
                } label: {
                    Text(currentWordIndex >= todaysWords.count - 1 ? "Finish" : "Next Word")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    // MARK: - Completed View
    private var completedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(correctAnswers == todaysWords.count ? "🏆" : "⭐")
                .font(.system(size: 70))

            Text(correctAnswers == todaysWords.count ? "Perfect Score!" : "Challenge Complete!")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ResultStatCell(value: "\(score)", label: "Score", color: .blue)
                ResultStatCell(value: "\(correctAnswers)/\(todaysWords.count)", label: "Correct", color: .green)
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button { dismiss() } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }

    // MARK: - Logic
    private func loadTodaysWords() {
        // Pick 5 random words for daily challenge
        let shuffled = allWords.filter { $0.gradeLevel == GradeLevel.grade3.rawValue }.shuffled()
        todaysWords = Array(shuffled.prefix(5))
        SpeechEngine.shared.speak(todaysWords.first?.text ?? "")
    }

    private func startChallenge() {
        currentWordIndex = 0
        score = 0
        correctAnswers = 0
        typedAnswer = ""
        showingFeedback = false
        isPlayingChallenge = true

        if let first = todaysWords.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                SpeechEngine.shared.speak(first.text)
            }
        }
    }

    private func submitDailyAnswer() {
        guard let word = currentWord else { return }
        let answer = typedAnswer.trimmingCharacters(in: .whitespaces)
        let correct = answer.lowercased() == word.text.lowercased()

        lastAnswerCorrect = correct
        showingFeedback = true
        typedAnswer = ""

        if correct {
            score += 100
            correctAnswers += 1
            HapticManager.success()
        } else {
            HapticManager.error()
        }
    }

    private func advanceWord() {
        showingFeedback = false
        lastAnswerCorrect = nil

        if currentWordIndex >= todaysWords.count - 1 {
            finishChallenge()
        } else {
            currentWordIndex += 1
            if let word = currentWord {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    SpeechEngine.shared.speak(word.text)
                }
            }
        }
    }

    private func finishChallenge() {
        isPlayingChallenge = false
        challengeCompleted = true

        // Save daily challenge result
        let challenge = DailyChallenge(
            date: Date(),
            gradeLevel: .grade3,
            wordIds: todaysWords.map { $0.id }
        )
        challenge.isCompleted = true
        challenge.score = score
        modelContext.insert(challenge)
        try? modelContext.save()

        AnalyticsService.shared.track(.dailyChallengeCompleted)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
}
