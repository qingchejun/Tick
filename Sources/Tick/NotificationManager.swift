import AppKit
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private var soundTimer: Timer?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func sendTimerComplete(note: String = "") {
        // Loop alert sound until dismissed
        NSSound(named: .init("Glass"))?.play()
        soundTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            NSSound(named: .init("Glass"))?.play()
        }

        // System notification as backup
        let content = UNMutableNotificationContent()
        content.title = "Time's up!"
        content.body = note.isEmpty ? "Your countdown timer has finished." : note
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Notification error: \(error)")
            }
        }
    }

    func stopSound() {
        soundTimer?.invalidate()
        soundTimer = nil
        NSSound(named: .init("Glass"))?.stop()
    }

    // Show notification even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
