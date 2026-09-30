import Foundation
import SwiftData

// MARK: - Repository Protocol (Dependency Inversion Principle)
protocol VapeDataRepositoryProtocol: AnyObject {
    func fetchTanks() throws -> [TankSetup]
    func fetchBatteries() throws -> [BatteryItem]
    func fetchLiquids() throws -> [LiquidItem]
    
    func save() throws
    func delete<T: PersistentModel>(_ model: T) throws
    func insert<T: PersistentModel>(_ model: T)
    
    // Two-Way Sync Helpers
    func upsertTank(id: UUID, name: String, wire: String, coilDate: Date, cottonDate: Date, activeLiquid: String, coilMax: Int, cottonMax: Int) throws
    func upsertBattery(id: UUID, code: String, brand: String, purchasedDate: Date, maxDays: Int, notes: String) throws
    func upsertLiquid(id: UUID, name: String, openedDate: Date, maxDays: Int, nicMg: String, volumeMl: String) throws
    func deleteTank(id: UUID) throws
    func deleteBattery(id: UUID) throws
    func deleteLiquid(id: UUID) throws
}

// MARK: - SwiftData Implementation of Repository
final class VapeDataRepository: VapeDataRepositoryProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func fetchTanks() throws -> [TankSetup] {
        let descriptor = FetchDescriptor<TankSetup>(sortBy: [SortDescriptor(\.tankName)])
        return try context.fetch(descriptor)
    }
    
    func fetchBatteries() throws -> [BatteryItem] {
        let descriptor = FetchDescriptor<BatteryItem>(sortBy: [SortDescriptor(\.code)])
        return try context.fetch(descriptor)
    }
    
    func fetchLiquids() throws -> [LiquidItem] {
        let descriptor = FetchDescriptor<LiquidItem>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor)
    }
    
    func insert<T: PersistentModel>(_ model: T) {
        context.insert(model)
    }
    
    func delete<T: PersistentModel>(_ model: T) throws {
        context.delete(model)
        try save()
    }
    
    func save() throws {
        try context.save()
    }
    
    func upsertTank(id: UUID, name: String, wire: String, coilDate: Date, cottonDate: Date, activeLiquid: String, coilMax: Int, cottonMax: Int) throws {
        let tanks = try fetchTanks()
        if let existing = tanks.first(where: { $0.id == id }) {
            existing.tankName = name
            existing.wireType = wire
            existing.coilInstalledDate = coilDate
            existing.cottonReplacedDate = cottonDate
            existing.activeLiquidName = activeLiquid
            existing.coilMaxDays = coilMax
            existing.cottonMaxDays = cottonMax
        } else {
            let newTank = TankSetup(
                id: id,
                tankName: name,
                wireType: wire,
                coilInstalledDate: coilDate,
                cottonReplacedDate: cottonDate,
                activeLiquidName: activeLiquid,
                coilMaxDays: coilMax,
                cottonMaxDays: cottonMax
            )
            insert(newTank)
        }
        try save()
    }
    
    func upsertBattery(id: UUID, code: String, brand: String, purchasedDate: Date, maxDays: Int, notes: String) throws {
        let batteries = try fetchBatteries()
        if let existing = batteries.first(where: { $0.id == id }) {
            existing.code = code
            existing.brandAndType = brand
            existing.purchasedDate = purchasedDate
            existing.maxDays = maxDays
            existing.notes = notes
        } else {
            let newBattery = BatteryItem(
                id: id,
                code: code,
                brandAndType: brand,
                purchasedDate: purchasedDate,
                maxDays: maxDays,
                notes: notes
            )
            insert(newBattery)
        }
        try save()
    }
    
    func upsertLiquid(id: UUID, name: String, openedDate: Date, maxDays: Int, nicMg: String, volumeMl: String) throws {
        let liquids = try fetchLiquids()
        if let existing = liquids.first(where: { $0.id == id }) {
            existing.name = name
            existing.openedDate = openedDate
            existing.maxDays = maxDays
            existing.nicMg = nicMg
            existing.volumeMl = volumeMl
        } else {
            let newLiquid = LiquidItem(
                id: id,
                name: name,
                openedDate: openedDate,
                maxDays: maxDays,
                nicMg: nicMg,
                volumeMl: volumeMl
            )
            insert(newLiquid)
        }
        try save()
    }
    
    func deleteTank(id: UUID) throws {
        let tanks = try fetchTanks()
        if let existing = tanks.first(where: { $0.id == id }) {
            try delete(existing)
        }
    }
    
    func deleteBattery(id: UUID) throws {
        let batteries = try fetchBatteries()
        if let existing = batteries.first(where: { $0.id == id }) {
            try delete(existing)
        }
    }
    
    func deleteLiquid(id: UUID) throws {
        let liquids = try fetchLiquids()
        if let existing = liquids.first(where: { $0.id == id }) {
            try delete(existing)
        }
    }
}
