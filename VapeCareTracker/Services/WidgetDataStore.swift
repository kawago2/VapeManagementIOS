import Foundation
import WidgetKit
import AppIntents

// MARK: - Multi-Tank Snapshot Model
public struct WidgetTankItem: Codable, Identifiable {
    public let id: String
    public let tankName: String
    public let wireType: String
    public let activeLiquid: String
    public let coilDaysPassed: Int
    public let coilMaxDays: Int
    public let coilOverdue: Bool
    public let cottonDaysPassed: Int
    public let cottonMaxDays: Int
    public let cottonOverdue: Bool
    
    public init(
        id: String = UUID().uuidString,
        tankName: String,
        wireType: String,
        activeLiquid: String,
        coilDaysPassed: Int,
        coilMaxDays: Int,
        coilOverdue: Bool,
        cottonDaysPassed: Int,
        cottonMaxDays: Int,
        cottonOverdue: Bool
    ) {
        self.id = id
        self.tankName = tankName
        self.wireType = wireType
        self.activeLiquid = activeLiquid
        self.coilDaysPassed = coilDaysPassed
        self.coilMaxDays = coilMaxDays
        self.coilOverdue = coilOverdue
        self.cottonDaysPassed = cottonDaysPassed
        self.cottonMaxDays = cottonMaxDays
        self.cottonOverdue = cottonOverdue
    }
}

public struct WidgetTankSnapshot: Codable {
    public let tanks: [WidgetTankItem]
    public let selectedIndex: Int
    public let updatedAt: Date
    
    public init(
        tanks: [WidgetTankItem],
        selectedIndex: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.tanks = tanks
        self.selectedIndex = selectedIndex
        self.updatedAt = updatedAt
    }
    
    public var currentTank: WidgetTankItem? {
        guard !tanks.isEmpty else { return nil }
        let safeIndex = max(0, min(selectedIndex, tanks.count - 1))
        return tanks[safeIndex]
    }
    
    public static var placeholder: WidgetTankSnapshot {
        WidgetTankSnapshot(
            tanks: [
                WidgetTankItem(
                    tankName: "Nitrous RTA",
                    wireType: "Alien Fused Clapton 0.22Ω",
                    activeLiquid: "Tokyo Banana 3mg",
                    coilDaysPassed: 4,
                    coilMaxDays: 14,
                    coilOverdue: false,
                    cottonDaysPassed: 2,
                    cottonMaxDays: 3,
                    cottonOverdue: false
                ),
                WidgetTankItem(
                    tankName: "Dead Rabbit Pro RDA",
                    wireType: "Dual Fused Clapton 0.16Ω",
                    activeLiquid: "Oat Drips V1 6mg",
                    coilDaysPassed: 7,
                    coilMaxDays: 14,
                    coilOverdue: false,
                    cottonDaysPassed: 3,
                    cottonMaxDays: 3,
                    cottonOverdue: true
                )
            ],
            selectedIndex: 0,
            updatedAt: Date()
        )
    }
}

// MARK: - App Intent for Interactive Navigation (Next / Previous Tank)
public struct NextTankIntent: AppIntent {
    public static var title: LocalizedStringResource = "Tank Berikutnya"
    public static var description = IntentDescription("Pindah ke tank berikutnya di widget")

    public init() {}

    public func perform() async throws -> some IntentResult {
        WidgetDataStore.shared.nextTank()
        return .result()
    }
}

public struct PrevTankIntent: AppIntent {
    public static var title: LocalizedStringResource = "Tank Sebelumnya"
    public static var description = IntentDescription("Pindah ke tank sebelumnya di widget")

    public init() {}

    public func perform() async throws -> some IntentResult {
        WidgetDataStore.shared.prevTank()
        return .result()
    }
}

// MARK: - Widget Data Store Protocol
public protocol WidgetDataStoreProtocol {
    func saveTanks(_ tanks: [WidgetTankItem])
    func loadSnapshot() -> WidgetTankSnapshot
    func nextTank()
    func prevTank()
}

// MARK: - Implementation with Shared File Fallback
public final class WidgetDataStore: WidgetDataStoreProtocol {
    public static let shared = WidgetDataStore()
    
    private let appGroupSuite = "group.com.local.vapecare"
    private let snapshotKey = "vapecare_widget_multitank_snapshot"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupSuite)
    }
    
    private var sharedFileURL: URL? {
        // Shared container folder when App Groups is enabled
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupSuite) {
            return container.appendingPathComponent("widget_data.json")
        }
        return nil
    }
    
    public init() {}
    
    public func saveTanks(_ items: [WidgetTankItem]) {
        let existing = loadSnapshot()
        let newIndex = min(existing.selectedIndex, max(0, items.count - 1))
        let snapshot = WidgetTankSnapshot(tanks: items, selectedIndex: newIndex, updatedAt: Date())
        persist(snapshot)
    }
    
    public func nextTank() {
        var snapshot = loadSnapshot()
        guard !snapshot.tanks.isEmpty else { return }
        let next = (snapshot.selectedIndex + 1) % snapshot.tanks.count
        snapshot = WidgetTankSnapshot(tanks: snapshot.tanks, selectedIndex: next, updatedAt: Date())
        persist(snapshot)
    }
    
    public func prevTank() {
        var snapshot = loadSnapshot()
        guard !snapshot.tanks.isEmpty else { return }
        let count = snapshot.tanks.count
        let prev = (snapshot.selectedIndex - 1 + count) % count
        snapshot = WidgetTankSnapshot(tanks: snapshot.tanks, selectedIndex: prev, updatedAt: Date())
        persist(snapshot)
    }
    
    public func loadSnapshot() -> WidgetTankSnapshot {
        // 1. Try reading from App Group UserDefaults
        if let defaults = sharedDefaults,
           let data = defaults.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(WidgetTankSnapshot.self, from: data) {
            return snapshot
        }
        
        // 2. Try reading from shared App Group File container
        if let fileURL = sharedFileURL,
           let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(WidgetTankSnapshot.self, from: data) {
            return snapshot
        }
        
        // 3. Fallback to standard UserDefaults (same process / preview)
        if let data = UserDefaults.standard.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(WidgetTankSnapshot.self, from: data) {
            return snapshot
        }
        
        return .placeholder
    }
    
    private func persist(_ snapshot: WidgetTankSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        
        // Save to App Group UserDefaults
        sharedDefaults?.set(data, forKey: snapshotKey)
        
        // Save to App Group File
        if let fileURL = sharedFileURL {
            try? data.write(to: fileURL)
        }
        
        // Save to standard as fallback
        UserDefaults.standard.set(data, forKey: snapshotKey)
        
        WidgetCenter.shared.reloadAllTimelines()
    }
}
