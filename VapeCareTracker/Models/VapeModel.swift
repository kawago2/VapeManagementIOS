import Foundation
import SwiftData

// MARK: - 1. Liquid Entity
@Model
final class LiquidItem: Identifiable, HealthTrackable {
    var id: UUID = UUID()
    var name: String = "Butterbread Peanut Butter"
    var openedDate: Date = Date()
    var maxDays: Int = 90
    var nicMg: String = "3mg"
    var volumeMl: String = "60ml"
    
    init(
        id: UUID = UUID(),
        name: String = "Butterbread Peanut Butter",
        openedDate: Date = Date(),
        maxDays: Int = 90,
        nicMg: String = "3mg",
        volumeMl: String = "60ml"
    ) {
        self.id = id
        self.name = name
        self.openedDate = openedDate
        self.maxDays = maxDays
        self.nicMg = nicMg
        self.volumeMl = volumeMl
    }
    
    var daysPassed: Int {
        HealthCalculator.shared.calculateDaysPassed(from: openedDate)
    }
    
    var healthStatus: ComponentHealthStatus {
        HealthCalculator.shared.calculateHealthStatus(startDate: openedDate, maxDays: maxDays)
    }
}

// MARK: - 2. Battery Entity
@Model
final class BatteryItem: Identifiable, HealthTrackable {
    var id: UUID = UUID()
    var code: String = "BAT-01"
    var brandAndType: String = "PVR Battery 18650"
    var purchasedDate: Date = Date()
    var maxDays: Int = 365
    var notes: String = ""
    
    init(
        id: UUID = UUID(),
        code: String = "BAT-01",
        brandAndType: String = "PVR Battery 18650",
        purchasedDate: Date = Date(),
        maxDays: Int = 365,
        notes: String = ""
    ) {
        self.id = id
        self.code = code
        self.brandAndType = brandAndType
        self.purchasedDate = purchasedDate
        self.maxDays = maxDays
        self.notes = notes
    }
    
    var daysPassed: Int {
        HealthCalculator.shared.calculateDaysPassed(from: purchasedDate)
    }
    
    var healthStatus: ComponentHealthStatus {
        HealthCalculator.shared.calculateHealthStatus(startDate: purchasedDate, maxDays: maxDays)
    }
}

// MARK: - 3. Tank Setup Entity
@Model
final class TankSetup: Identifiable {
    var id: UUID = UUID()
    var tankName: String = "Tank TRML"
    var wireType: String = "Coil Teko Baby Alien (0.35Ω)"
    var coilInstalledDate: Date = Date()
    var cottonReplacedDate: Date = Date()
    var activeLiquidName: String = "Butterbread Peanut Butter"
    
    var coilMaxDays: Int = 14
    var cottonMaxDays: Int = 4
    
    init(
        id: UUID = UUID(),
        tankName: String = "Tank TRML",
        wireType: String = "Coil Teko Baby Alien (0.35Ω)",
        coilInstalledDate: Date = Date(),
        cottonReplacedDate: Date = Date(),
        activeLiquidName: String = "Butterbread Peanut Butter",
        coilMaxDays: Int = 14,
        cottonMaxDays: Int = 4
    ) {
        self.id = id
        self.tankName = tankName
        self.wireType = wireType
        self.coilInstalledDate = coilInstalledDate
        self.cottonReplacedDate = cottonReplacedDate
        self.activeLiquidName = activeLiquidName
        self.coilMaxDays = coilMaxDays
        self.cottonMaxDays = cottonMaxDays
    }
    
    var coilDaysPassed: Int {
        HealthCalculator.shared.calculateDaysPassed(from: coilInstalledDate)
    }
    
    var cottonDaysPassed: Int {
        HealthCalculator.shared.calculateDaysPassed(from: cottonReplacedDate)
    }
    
    var coilHealthStatus: ComponentHealthStatus {
        HealthCalculator.shared.calculateHealthStatus(startDate: coilInstalledDate, maxDays: coilMaxDays)
    }
    
    var cottonHealthStatus: ComponentHealthStatus {
        HealthCalculator.shared.calculateHealthStatus(startDate: cottonReplacedDate, maxDays: cottonMaxDays)
    }
}
