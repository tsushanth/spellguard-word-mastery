//
//  GradeLevel.swift
//  SpellGuard
//
//  Grade level definitions for word categories
//

import Foundation
import SwiftUI

// MARK: - Grade Level
enum GradeLevel: String, CaseIterable, Codable, Identifiable {
    case kindergarten = "K"
    case grade1 = "1"
    case grade2 = "2"
    case grade3 = "3"
    case grade4 = "4"
    case grade5 = "5"
    case grade6 = "6"
    case grade7 = "7"
    case grade8 = "8"
    case grade9 = "9"
    case grade10 = "10"
    case grade11 = "11"
    case grade12 = "12"
    case sat = "SAT"
    case act = "ACT"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kindergarten: return "Kindergarten"
        case .grade1: return "1st Grade"
        case .grade2: return "2nd Grade"
        case .grade3: return "3rd Grade"
        case .grade4: return "4th Grade"
        case .grade5: return "5th Grade"
        case .grade6: return "6th Grade"
        case .grade7: return "7th Grade"
        case .grade8: return "8th Grade"
        case .grade9: return "9th Grade"
        case .grade10: return "10th Grade"
        case .grade11: return "11th Grade"
        case .grade12: return "12th Grade"
        case .sat: return "SAT Prep"
        case .act: return "ACT Prep"
        }
    }

    var shortName: String {
        switch self {
        case .kindergarten: return "K"
        case .sat: return "SAT"
        case .act: return "ACT"
        default: return "Grade \(rawValue)"
        }
    }

    var isPremium: Bool {
        switch self {
        case .kindergarten, .grade1, .grade2, .grade3:
            return false
        default:
            return true
        }
    }

    var colorHex: String {
        switch self {
        case .kindergarten: return "#FF6B6B"
        case .grade1: return "#FF8E53"
        case .grade2: return "#FFA500"
        case .grade3: return "#FFD700"
        case .grade4: return "#9ACD32"
        case .grade5: return "#32CD32"
        case .grade6: return "#00CED1"
        case .grade7: return "#1E90FF"
        case .grade8: return "#6A5ACD"
        case .grade9: return "#9370DB"
        case .grade10: return "#FF69B4"
        case .grade11: return "#DC143C"
        case .grade12: return "#8B0000"
        case .sat: return "#FFD700"
        case .act: return "#C0C0C0"
        }
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    var wordCount: Int {
        switch self {
        case .kindergarten: return 100
        case .grade1: return 150
        case .grade2: return 200
        case .grade3: return 250
        case .grade4: return 300
        case .grade5: return 350
        case .grade6: return 400
        case .grade7: return 450
        case .grade8: return 500
        case .grade9: return 550
        case .grade10: return 600
        case .grade11: return 650
        case .grade12: return 700
        case .sat: return 500
        case .act: return 500
        }
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
