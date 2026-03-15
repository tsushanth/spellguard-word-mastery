//
//  Word.swift
//  SpellGuard
//
//  Word model with SwiftData
//

import Foundation
import SwiftData

// MARK: - Word Model
@Model
final class Word {
    var id: UUID
    var text: String
    var definition: String
    var exampleSentence: String
    var gradeLevel: String
    var partOfSpeech: String
    var phonetic: String
    var synonyms: [String]
    var antonyms: [String]
    var origin: String
    var difficulty: Int // 1-5
    var isFavorite: Bool
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        text: String,
        definition: String,
        exampleSentence: String = "",
        gradeLevel: String = GradeLevel.grade1.rawValue,
        partOfSpeech: String = "noun",
        phonetic: String = "",
        synonyms: [String] = [],
        antonyms: [String] = [],
        origin: String = "",
        difficulty: Int = 1,
        isFavorite: Bool = false,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.definition = definition
        self.exampleSentence = exampleSentence
        self.gradeLevel = gradeLevel
        self.partOfSpeech = partOfSpeech
        self.phonetic = phonetic
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.origin = origin
        self.difficulty = difficulty
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
    }

    var gradeLevelEnum: GradeLevel {
        GradeLevel(rawValue: gradeLevel) ?? .grade1
    }

    var difficultyLabel: String {
        switch difficulty {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        case 4: return "Very Hard"
        case 5: return "Expert"
        default: return "Unknown"
        }
    }
}
