//
//  SpeechEngine.swift
//  SpellGuard
//
//  Text-to-speech engine for word pronunciation
//

import Foundation
import AVFoundation

// MARK: - Speech Engine
@MainActor
@Observable
final class SpeechEngine: NSObject {
    static let shared = SpeechEngine()

    // MARK: - Properties
    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking = false
    private(set) var currentWord: String = ""

    var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    var volume: Float = 1.0
    var selectedVoice: String = "com.apple.ttsbundle.Samantha-compact"

    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }

    // MARK: - Audio Session
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Speak Word
    func speak(_ word: String, slow: Bool = false) {
        guard !word.isEmpty else { return }
        stop()

        currentWord = word
        let utterance = AVSpeechUtterance(string: word)

        // Configure voice
        if let voice = AVSpeechSynthesisVoice(identifier: selectedVoice) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        utterance.rate = slow ? AVSpeechUtteranceMinimumSpeechRate + 0.1 : speechRate
        utterance.volume = volume
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0.1

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    // MARK: - Speak Sentence
    func speakSentence(_ sentence: String) {
        guard !sentence.isEmpty else { return }
        stop()

        currentWord = sentence
        let utterance = AVSpeechUtterance(string: sentence)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.volume = volume
        utterance.postUtteranceDelay = 0.3

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    // MARK: - Spell Out
    func spellOut(_ word: String) {
        guard !word.isEmpty else { return }
        stop()

        let letters = word.uppercased().map { String($0) }.joined(separator: ". ")
        let utterance = AVSpeechUtterance(string: letters)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceMinimumSpeechRate + 0.2
        utterance.volume = volume
        utterance.postUtteranceDelay = 0.1

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    // MARK: - Pronounce with Context
    func pronounceWithContext(word: String, definition: String, example: String) {
        stop()

        let sequence: [(String, Float)] = [
            (word, AVSpeechUtteranceMinimumSpeechRate + 0.1),
            ("Definition: \(definition)", AVSpeechUtteranceDefaultSpeechRate * 0.9),
            ("Example: \(example)", AVSpeechUtteranceDefaultSpeechRate * 0.9),
            (word, AVSpeechUtteranceMinimumSpeechRate + 0.1)
        ]

        for (text, rate) in sequence {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = rate
            utterance.volume = volume
            utterance.postUtteranceDelay = 0.5
            synthesizer.speak(utterance)
        }

        isSpeaking = true
    }

    // MARK: - Stop
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentWord = ""
    }

    // MARK: - Pause / Resume
    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        synthesizer.continueSpeaking()
    }

    // MARK: - Available Voices
    var availableEnglishVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechEngine: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            if !synthesizer.isSpeaking {
                self.isSpeaking = false
                self.currentWord = ""
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentWord = ""
        }
    }
}
