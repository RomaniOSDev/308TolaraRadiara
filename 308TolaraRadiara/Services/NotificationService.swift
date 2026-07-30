import Foundation
import UserNotifications
import UIKit

enum NotificationService {
    private static let dailyId = "tr_daily_reminder"
    private static let thresholdId = "tr_threshold_alert"

    static func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    static func reschedule(from settings: ReminderSettings) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyId])

        guard settings.dailyEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Solar Check-In"
        content.body = "Time to refresh today’s radiation reading."
        content.sound = HapticService.soundEnabled ? .default : nil

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: settings.reminderDateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(identifier: dailyId, content: content, trigger: trigger)
        center.add(request)
    }

    static func notifyThresholdIfNeeded(value: Double, thresholds: AlertThresholds, enabled: Bool) {
        guard enabled else { return }
        guard value <= thresholds.low || value >= thresholds.high else { return }

        let content = UNMutableNotificationContent()
        content.title = "Radiation Outside Range"
        if value >= thresholds.high {
            content.body = "Current level \(Int(value)) W/m² is above your high alert."
        } else {
            content.body = "Current level \(Int(value)) W/m² is below your low alert."
        }
        content.sound = HapticService.soundEnabled ? .default : nil

        let request = UNNotificationRequest(
            identifier: "\(thresholdId)_\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
