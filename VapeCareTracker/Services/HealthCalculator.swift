import Foundation

// MARK: - Health Status Level Enum
enum HealthLevel {
    case safe
    case attention
    case overdue
}

// MARK: - Component Health Status Value Object
struct ComponentHealthStatus {
    let daysPassed: Int
    let maxDays: Int
    let usageRatio: Double
    
    var percentage: Int {
        Int((usageRatio * 100).rounded())
    }
    
    var remainingDays: Int {
        max(0, maxDays - daysPassed)
    }
    
    var isOverdue: Bool {
        daysPassed >= maxDays
    }
    
    var statusLevel: HealthLevel {
        if usageRatio >= 1.0 {
            return .overdue
        } else if usageRatio >= 0.75 {
            return .attention
        } else {
            return .safe
        }
    }
}

// MARK: - Health Trackable Protocol (Interface Segregation Principle)
protocol HealthTrackable {
    var daysPassed: Int { get }
    var healthStatus: ComponentHealthStatus { get }
}

// MARK: - Health Calculator Engine (Single Responsibility Principle)
final class HealthCalculator {
    static let shared = HealthCalculator()
    
    private let calendar: Calendar
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }
    
    func calculateDaysPassed(from startDate: Date, to endDate: Date = Date()) -> Int {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(0, components.day ?? 0)
    }
    
    func calculateHealthStatus(startDate: Date, maxDays: Int, referenceDate: Date = Date()) -> ComponentHealthStatus {
        let daysPassed = calculateDaysPassed(from: startDate, to: referenceDate)
        let validMaxDays = max(1, maxDays)
        let ratio = Double(daysPassed) / Double(validMaxDays)
        return ComponentHealthStatus(daysPassed: daysPassed, maxDays: validMaxDays, usageRatio: ratio)
    }
}
