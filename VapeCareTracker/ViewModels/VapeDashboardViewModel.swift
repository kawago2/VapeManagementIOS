import Foundation
import SwiftData

@MainActor
final class VapeDashboardViewModel: ObservableObject {
    private let repository: VapeDataRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    let syncService: any TursoSyncServiceProtocol
    
    @Published var tanks: [TankSetup] = []
    @Published var batteries: [BatteryItem] = []
    @Published var liquids: [LiquidItem] = []
    
    // Status metrics
    var overdueCoilCount: Int {
        tanks.filter { $0.coilHealthStatus.isOverdue }.count
    }
    
    var overdueCottonCount: Int {
        tanks.filter { $0.cottonHealthStatus.isOverdue }.count
    }
    
    init(
        repository: VapeDataRepositoryProtocol,
        notificationService: NotificationServiceProtocol,
        syncService: any TursoSyncServiceProtocol = TursoSyncService.shared
    ) {
        self.repository = repository
        self.notificationService = notificationService
        self.syncService = syncService
    }
    
    convenience init(repository: VapeDataRepositoryProtocol) {
        self.init(repository: repository, notificationService: NotificationManager.shared, syncService: TursoSyncService.shared)
    }
    
    func onAppear() async {
        loadAllData()
        _ = await notificationService.requestAuthorization()
        notificationService.scheduleReminders(for: tanks)
        
        // Alur utama: Ambil (pull) data dari DB terlebih dahulu
        if TursoConfig.isConfigured {
            await pullFromCloud()
        }
    }
    
    // 1. Get dari DB
    func pullFromCloud() async {
        do {
            try await syncService.pullDataFromCloud(repository: repository)
            loadAllData()
            notificationService.scheduleReminders(for: tanks)
            syncService.lastSyncDate = Date()
            syncService.lastSyncStatus = "Berhasil memuat data dari cloud."
        } catch {
            print("Cloud pull error: \(error.localizedDescription)")
            syncService.lastSyncStatus = "Gagal memuat: \(error.localizedDescription)"
        }
    }
    
    func syncWithCloud() async {
        await pullFromCloud()
    }
    
    func loadAllData() {
        do {
            self.tanks = try repository.fetchTanks()
            self.batteries = try repository.fetchBatteries()
            self.liquids = try repository.fetchLiquids()
        } catch {
            print("Error fetching data: \(error.localizedDescription)")
        }
    }
    
    // 2. Simpan dan Tambah Data (Enkapsulasi OOP & DIP)
    func saveTank(
        existing: TankSetup?,
        tankName: String,
        wireType: String,
        coilInstalledDate: Date,
        cottonReplacedDate: Date,
        activeLiquidName: String,
        coilMaxDays: Int,
        cottonMaxDays: Int
    ) {
        let savedTank: TankSetup
        if let existing = existing {
            existing.tankName = tankName
            existing.wireType = wireType
            existing.coilInstalledDate = coilInstalledDate
            existing.cottonReplacedDate = cottonReplacedDate
            existing.activeLiquidName = activeLiquidName
            existing.coilMaxDays = coilMaxDays
            existing.cottonMaxDays = cottonMaxDays
            savedTank = existing
        } else {
            let newTank = TankSetup(
                tankName: tankName,
                wireType: wireType,
                coilInstalledDate: coilInstalledDate,
                cottonReplacedDate: cottonReplacedDate,
                activeLiquidName: activeLiquidName,
                coilMaxDays: coilMaxDays,
                cottonMaxDays: cottonMaxDays
            )
            repository.insert(newTank)
            savedTank = newTank
        }
        saveAndSyncNotifications()
        Task {
            await syncService.uploadTank(savedTank)
        }
    }
    
    func saveBattery(
        existing: BatteryItem?,
        code: String,
        brandAndType: String,
        purchasedDate: Date,
        maxDays: Int,
        notes: String
    ) {
        let savedBattery: BatteryItem
        if let existing = existing {
            existing.code = code
            existing.brandAndType = brandAndType
            existing.purchasedDate = purchasedDate
            existing.maxDays = maxDays
            existing.notes = notes
            savedBattery = existing
        } else {
            let newBattery = BatteryItem(
                code: code,
                brandAndType: brandAndType,
                purchasedDate: purchasedDate,
                maxDays: maxDays,
                notes: notes
            )
            repository.insert(newBattery)
            savedBattery = newBattery
        }
        saveDataOnly()
        Task {
            await syncService.uploadBattery(savedBattery)
        }
    }
    
    func saveLiquid(
        existing: LiquidItem?,
        name: String,
        openedDate: Date,
        maxDays: Int,
        nicMg: String,
        volumeMl: String
    ) {
        let savedLiquid: LiquidItem
        if let existing = existing {
            existing.name = name
            existing.openedDate = openedDate
            existing.maxDays = maxDays
            existing.nicMg = nicMg
            existing.volumeMl = volumeMl
            savedLiquid = existing
        } else {
            let newLiquid = LiquidItem(
                name: name,
                openedDate: openedDate,
                maxDays: maxDays,
                nicMg: nicMg,
                volumeMl: volumeMl
            )
            repository.insert(newLiquid)
            savedLiquid = newLiquid
        }
        saveDataOnly()
        Task {
            await syncService.uploadLiquid(savedLiquid)
        }
    }
    
    // Quick Actions
    func quickResetCotton(for tank: TankSetup) {
        tank.cottonReplacedDate = Date()
        saveAndSyncNotifications()
        Task {
            await syncService.uploadTank(tank)
        }
    }
    
    func quickResetCoil(for tank: TankSetup) {
        tank.coilInstalledDate = Date()
        saveAndSyncNotifications()
        Task {
            await syncService.uploadTank(tank)
        }
    }
    
    func updateActiveLiquid(for tank: TankSetup, liquidName: String) {
        tank.activeLiquidName = liquidName
        saveDataOnly()
        Task {
            await syncService.uploadTank(tank)
        }
    }
    
    // 3. Penghapusan data -> Hapus di DB
    func deleteTank(_ tank: TankSetup) {
        let id = tank.id
        do {
            try repository.delete(tank)
            loadAllData()
            notificationService.scheduleReminders(for: tanks)
            Task {
                await syncService.deleteFromCloud(table: "tanks", id: id)
            }
        } catch {
            print("Error deleting tank: \(error.localizedDescription)")
        }
    }
    
    func deleteBattery(_ battery: BatteryItem) {
        let id = battery.id
        do {
            try repository.delete(battery)
            loadAllData()
            Task {
                await syncService.deleteFromCloud(table: "batteries", id: id)
            }
        } catch {
            print("Error deleting battery: \(error.localizedDescription)")
        }
    }
    
    func deleteLiquid(_ liquid: LiquidItem) {
        let id = liquid.id
        do {
            try repository.delete(liquid)
            loadAllData()
            Task {
                await syncService.deleteFromCloud(table: "liquids", id: id)
            }
        } catch {
            print("Error deleting liquid: \(error.localizedDescription)")
        }
    }
    
    private func saveAndSyncNotifications() {
        do {
            try repository.save()
            loadAllData()
            notificationService.scheduleReminders(for: tanks)
        } catch {
            print("Error saving: \(error.localizedDescription)")
        }
    }
    
    private func saveDataOnly() {
        do {
            try repository.save()
            loadAllData()
        } catch {
            print("Error saving data: \(error.localizedDescription)")
        }
    }
}
