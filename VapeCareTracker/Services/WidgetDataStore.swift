import Foundation
import WidgetKit

// MARK: - Widget Snapshot Data Model
public struct WidgetTankSnapshot: Codable {
    public let tankName: String
    public let wireType: String
    public let activeLiquid: String
    public let coilDaysPassed: Int
    public let coilMaxDays: Int
    public let coilOverdue: Bool
    public let cottonDaysPassed: Int
    public let cottonMaxDays: Int
    public let cottonOverdue: Bool
    public let updatedAt: Date
    
    public init(
        tankName: String,
        wireType: String,
        activeLiquid: String,
        coilDaysPassed: Int,
        coilMaxDays: Int,
        coilOverdue: Bool,
        cottonDaysPassed: Int,
        cottonMaxDays: Int,
        cottonOverdue: Bool,
        updatedAt: Date = Date()
    ) {
        self.tankName = tankName
        self.wireType = wireType
        self.activeLiquid = activeLiquid
        self.coilDaysPassed = coilDaysPassed
        self.coilMaxDays = coilMaxDays
        self.coilOverdue = coilOverdue
        self.cottonDaysPassed = cottonDaysPassed
        self.cottonMaxDays = cottonMaxDays
        self.cottonOverdue = cottonOverdue
        self.updatedAt = updatedAt
    }
    
    public static var placeholder: WidgetTankSnapshot {
        WidgetTankSnapshot(
            tankName: "Nitrous RTA",
            wireType: "Alien Fused Clapton 0.22Ω",
            activeLiquid: "Tokyo Banana 3mg",
            coilDaysPassed: 4,
            coilMaxDays: 14,
            coilOverdue: false,
            cottonDaysPassed: 2,
            cottonMaxDays: 3,
            cottonOverdue: false,
            updatedAt: Date()
        )
    }
}

// MARK: - Widget Data Store Protocol
public protocol WidgetDataStoreProtocol {
    func saveSnapshot(_ snapshot: WidgetTankSnapshot)
    func loadSnapshot() -> WidgetTankSnapshot?
}

// MARK: - Implementation
public final class WidgetDataStore: WidgetDataStoreProtocol {
    public static let shared = WidgetDataStore()
    
    private let appGroupSuite = "group.com.local.vapecare"
    private let snapshotKey = "vapecare_widget_snapshot"
    
    // Fallback to standard if app group isn't provisioned yet
    private var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupSuite) ?? .standard
    }
    
    public init() {}
    
    public func saveSnapshot(_ snapshot: WidgetTankSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    public func loadSnapshot() -> WidgetTankSnapshot? {
        guard let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetTankSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }
}
