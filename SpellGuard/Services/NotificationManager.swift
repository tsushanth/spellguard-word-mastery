//
//  NotificationManager.swift
//  SpellGuard
//
//  Local notification management
//

import Foundation
import UserNotifications

// MARK: - Notification Manager
@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var isAuthorized: Bool = false

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = authorizationStatus == .authorized
    }

    // MARK: - Daily Challenge Reminder
    func scheduleDailyChallenge(at hour: Int = 9, minute: Int = 0) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily Word Challenge!"
        content.body = "Your daily spelling challenge is ready. Keep your streak alive!"
        content.sound = .default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily.challenge",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule daily challenge notification: \(error)")
            }
        }
    }

    // MARK: - Study Reminder
    func scheduleStudyReminder(days: [Int] = [2, 4, 6], at hour: Int = 18) {
        guard isAuthorized else { return }

        for day in days {
            let content = UNMutableNotificationContent()
            content.title = "Time to Practice!"
            content.body = "Don't forget to review your spelling words today."
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.weekday = day
            dateComponents.hour = hour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "study.reminder.\(day)",
                content: content,
                trigger: trigger
            )

            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule study reminder: \(error)")
                }
            }
        }
    }

    // MARK: - Streak Reminder
    func scheduleStreakReminder(streakCount: Int) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Keep Your \(streakCount)-Day Streak!"
        content.body = "You're on a roll! Don't break your spelling streak."
        content.sound = .default

        // Schedule for 8 PM if not yet practiced today
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak.reminder",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule streak reminder: \(error)")
            }
        }
    }

    // MARK: - Cancel
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
