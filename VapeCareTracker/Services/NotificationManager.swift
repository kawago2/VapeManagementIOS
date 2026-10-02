import Foundation
import UserNotifications

// MARK: - Notification Service Protocol (Dependency Inversion Principle)
@MainActor
protocol NotificationServiceProtocol: AnyObject {
    var isPermissionGranted: Bool { get }
    func requestAuthorization() async -> Bool
    func scheduleReminders(for tanks: [TankSetup])
    func removeAllNotifications()
}

@MainActor
final class NotificationManager: ObservableObject, NotificationServiceProtocol {
    static let shared = NotificationManager()
    
    @Published private(set) var isPermissionGranted: Bool = false
    private let notificationCenter: UNUserNotificationCenter
    
    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        self.isPermissionGranted = (settings.authorizationStatus == .authorized)
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            self.isPermissionGranted = granted
            return granted
        } catch {
            self.isPermissionGranted = false
            return false
        }
    }
    
    func removeAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func scheduleReminders(for tanks: [TankSetup]) {
        removeAllNotifications()
        
        for tank in tanks {
            // Cotton reminder
            scheduleDateNotification(
                identifier: "cotton_\(tank.id.uuidString)",
                title: String(localized: "Time to Change Cotton! 💨"),
                body: "\(tank.tankName): " + String(localized: "Cotton has reached the limit (\(tank.cottonMaxDays) days)."),
                startDate: tank.cottonReplacedDate,
                targetDays: tank.cottonMaxDays
            )
            
            // Coil reminder
            scheduleDateNotification(
                identifier: "coil_\(tank.id.uuidString)",
                title: String(localized: "Time to Check/Change Coil! ⚡️"),
                body: "\(tank.tankName): " + String(localized: "Coil age has reached (\(tank.coilMaxDays) days)."),
                startDate: tank.coilInstalledDate,
                targetDays: tank.coilMaxDays
            )
        }
    }
    
    private func scheduleDateNotification(
        identifier: String,
        title: String,
        body: String,
        startDate: Date,
        targetDays: Int
    ) {
        let calendar = Calendar.current
        guard let targetDate = calendar.date(byAdding: .day, value: targetDays, to: startDate) else { return }
        if targetDate < Date() { return }
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
        dateComponents.hour = 9
        dateComponents.minute = 0
        dateComponents.second = 0
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        notificationCenter.add(request)
    }
}
