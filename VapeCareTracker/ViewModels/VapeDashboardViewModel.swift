import Foundation
import SwiftUI
import SwiftData

@MainActor
final class VapeDashboardViewModel: ObservableObject {
    
    private let repository: VapeDataRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    let syncService: any TursoSyncServiceProtocol
    private let exportService: DataExportServiceProtocol
    
    @Published var tanks: [TankSetup] = []
    @Published var batteries: [BatteryItem] = []
    @Published var liquids: [LiquidItem] = []
    @Published var maintenanceLogs: [MaintenanceLog] = []
    
    // Refresh & Toast feedback state
    @Published var isRefreshing: Bool = false
    @Published var toastMessage: String? = nil
    @Published var isToastError: Bool = false
    
    // Search query state
    @Published var searchText: String = ""
    
    // Filtered collections based on searchText
    var filteredTanks: [TankSetup] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return tanks }
        return tanks.filter {
            $0.tankName.lowercased().contains(query) ||
            $0.wireType.lowercased().contains(query) ||
            $0.activeLiquidName.lowercased().contains(query)
        }
    }
    
    var filteredBatteries: [BatteryItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return batteries }
        return batteries.filter {
            $0.code.lowercased().contains(query) ||
            $0.brandAndType.lowercased().contains(query) ||
            $0.notes.lowercased().contains(query)
        }
    }
    
    var filteredLiquids: [LiquidItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return liquids }
        return liquids.filter {
            $0.name.lowercased().contains(query) ||
            $0.nicMg.lowercased().contains(query) ||
            $0.volumeMl.lowercased().contains(query)
        }
    }
    
    // Status metrics
    var overdueCoilCount: Int {
        tanks.filter { $0.coilHealthStatus.isOverdue }.count
    }
    
    var overdueCottonCount: Int {
        tanks.filter { $0.cottonHealthStatus.isOverdue }.count
    }
    
    init(
        repository: VapeDataRepositoryProtocol,
        notificationService: NotificationServiceProtocol? = nil,
        syncService: (any TursoSyncServiceProtocol)? = nil,
        exportService: DataExportServiceProtocol? = nil
    ) {
        self.repository = repository
        self.notificationService = notificationService ?? NotificationManager.shared
        self.syncService = syncService ?? TursoSyncService.shared
        self.exportService = exportService ?? DataExportService.shared
    }
    
    func onAppear() async {
        loadAllData()
        _ = await notificationService.requestAuthorization()
        notificationService.scheduleReminders(for: tanks)
        
        // Primary flow: Pull data from remote cloud database if configured
        if TursoConfig.isConfigured {
            await pullFromCloud(showToast: false)
        }
    }
    
    // Fetch data from database with animated feedback and toast
    func pullFromCloud(showToast: Bool = true) async {
        guard !isRefreshing else { return }
        
        let startTime = Date()
        withAnimation(.easeInOut(duration: 0.2)) {
            isRefreshing = true
        }
        syncService.isSyncing = true
        
        defer {
            withAnimation(.easeInOut(duration: 0.2)) {
                isRefreshing = false
            }
            syncService.isSyncing = false
        }
        
        guard TursoConfig.isConfigured else {
            if showToast {
                // Brief pause so the refresh spinner remains perceptible
                try? await Task.sleep(nanoseconds: 400_000_000)
                showToastNotification(String(localized: "Database URL atau Auth Token belum disetel"), isError: true)
            }
            return
        }
        
        do {
            try await syncService.pullDataFromCloud(repository: repository)
            loadAllData()
            notificationService.scheduleReminders(for: tanks)
            syncService.lastSyncDate = Date()
            syncService.lastSyncStatus = String(localized: "Data berhasil dimuat dari cloud!")
            
            // Ensure spinner displays for at least 500ms for user feedback
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < 0.5 {
                let remainingNs = UInt64((0.5 - elapsed) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: remainingNs)
            }
            
            if showToast {
                showToastNotification(String(localized: "Sinkronisasi cloud berhasil!"))
            }
        } catch is CancellationError {
            // Task was cancelled normally by SwiftUI (e.g. scroll release, navigation)
            print("Cloud pull task cancelled normally.")
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession task was cancelled
            print("Cloud pull network cancelled.")
        } catch {
            let errorText = error.localizedDescription
            print("Cloud pull error: \(errorText)")
            syncService.lastSyncStatus = String(localized: "Gagal memuat: \(errorText)")
            
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < 0.5 {
                let remainingNs = UInt64((0.5 - elapsed) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: remainingNs)
            }
            
            if showToast {
                showToastNotification(String(localized: "Gagal refresh: \(errorText)"), isError: true)
            }
        }
    }
    
    func syncWithCloud() async {
        await pullFromCloud(showToast: true)
    }
    
    private func showToastNotification(_ message: String, isError: Bool = false) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.toastMessage = message
            self.isToastError = isError
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                if self.toastMessage == message {
                    self.toastMessage = nil
                }
            }
        }
    }
    
    func loadAllData() {
        do {
            self.tanks = try repository.fetchTanks()
            self.batteries = try repository.fetchBatteries()
            self.liquids = try repository.fetchLiquids()
            self.maintenanceLogs = try repository.fetchMaintenanceLogs()
            self.syncWidgetSnapshot()
        } catch {
            print("Error fetching data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Maintenance Log Actions
    func recordMaintenanceLog(tankId: UUID, tankName: String, actionType: String, notes: String = "") {
        let log = MaintenanceLog(
            tankId: tankId,
            tankName: tankName,
            actionType: actionType,
            date: Date(),
            notes: notes
        )
        repository.insert(log)
        do {
            try repository.save()
            self.maintenanceLogs = try repository.fetchMaintenanceLogs()
        } catch {
            print("Error recording maintenance log: \(error.localizedDescription)")
        }
    }
    
    func deleteMaintenanceLog(_ log: MaintenanceLog) {
        do {
            try repository.delete(log)
            self.maintenanceLogs = try repository.fetchMaintenanceLogs()
        } catch {
            print("Error deleting maintenance log: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Export / Backup Helpers
    func exportJSON() throws -> URL {
        return try exportService.generateJSONExport(
            tanks: tanks,
            batteries: batteries,
            liquids: liquids,
            logs: maintenanceLogs
        )
    }
    
    func exportCSV() throws -> URL {
        return try exportService.generateCSVExport(
            tanks: tanks,
            batteries: batteries,
            liquids: liquids,
            logs: maintenanceLogs
        )
    }
    
    // MARK: - Save and Insert Operations (OOP & DIP Encaspulation)
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
        recordMaintenanceLog(tankId: tank.id, tankName: tank.tankName, actionType: "cotton", notes: "Installed fresh cotton")
        Task {
            await syncService.uploadTank(tank)
        }
    }
    
    func quickResetCoil(for tank: TankSetup) {
        tank.coilInstalledDate = Date()
        saveAndSyncNotifications()
        recordMaintenanceLog(tankId: tank.id, tankName: tank.tankName, actionType: "coil", notes: "Installed new coil (\(tank.wireType))")
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
    
    // Deletion Operations -> Remote & Local
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
    
    private func syncWidgetSnapshot() {
        let items: [WidgetTankItem] = tanks.map { tank in
            WidgetTankItem(
                id: tank.id.uuidString,
                tankName: tank.tankName,
                wireType: tank.wireType,
                activeLiquid: tank.activeLiquidName,
                coilDaysPassed: tank.coilDaysPassed,
                coilMaxDays: tank.coilMaxDays,
                coilOverdue: tank.coilHealthStatus.isOverdue,
                cottonDaysPassed: tank.cottonDaysPassed,
                cottonMaxDays: tank.cottonMaxDays,
                cottonOverdue: tank.cottonHealthStatus.isOverdue
            )
        }
        WidgetDataStore.shared.saveTanks(items)
    }
}
